#!/usr/bin/env php
<?php
declare(strict_types=1);

/**
 * A quick tool for patching the boot_params check in the DSM kernel image
 * This lets you tinker with the initial ramdisk contents without disabling mount() features and modules loading
 *
 * The overall pattern we need to find is:
 *  - an CDECL function
 *  - does "LOCK OR [const-ptr],n" 4x
 *  - values of ORs are 1/2/4/8 respectively
 *  - [const-ptr] is always the same
 *
 * Usage: php patch-boot_params-check.php vmlinux vmlinux-mod
 */

require __DIR__ . '/common.php';

if ($argc < 2 || $argc > 3) {
    perr("Usage: " . $argv[0] . " <inFile> [<outFile>]\n", true);
}

$file = getArgFilePath(1);
perr("\nGenerating patch for $file\n");

//The function will reside in init code part. We don't care we may potentially search beyond as we expect it to be found
$codeAddr = getELFSectionAddr($file, '.init.text', 3);

//Finding a function boundary is non-trivial really as patters can vary, we can have multiple exit points, and in CISC
// there are many things which may match e.g. "PUSH EBP". Implementing even a rough disassembler is pointless.
//However, we can certainly cheat here as we know with CDECL a non-empty function will always contain one or more
// PUSH (0x41) R12-R15 (0x54-57) sequences. Then we can search like a 1K forward for these characteristic LOCK OR.
const PUSH_R12_R15_SEQ = [0x41, [0x54, 0x57]];
const PUSH_R12_R15_SEQ_LEN = 2;
const LOCK_OR_LOOK_AHEAD = 1024;
const LOCK_OR_PTR_SEQs = [
    [0xF0, 0x80, null, null, null, null, null, 0x01],
    [0xF0, 0x80, null, null, null, null, null, 0x02],
    [0xF0, 0x80, null, null, null, null, null, 0x04],
    [0xF0, 0x80, null, null, null, null, null, 0x08],
];
const LOCK_OR_PTR_SEQs_NUM = 4; //how many sequences we are expecting
const LOCK_OR_PTR_SEQ_LEN = 8; //length of a single sequence

$fp = getFileMemMapped($file); //Read the whole file to memory to make fseet/fread much faster
$pos = $codeAddr; //Start from where code starts
$orsPos = null; //When matched it will contain our resulting file offsets to LOCK(); OR BYTE PTR [rip+...],0x calls
perr("Looking for f() candidates...\n");
do {
    $find = findSequenceWithWildcard($fp, PUSH_R12_R15_SEQ, $pos, -1);
    if ($find === -1) {
        break; //no more "functions" left
    }

    perr("\rAnalyzing f() candidate @ " . decTo32bUFhex($pos));

    //we found something looking like PUSH R12-R15, now find the ORs
    $orsPos = []; //file offsets where LOCK() calls should start
    $orsPosNum = 0; //Number of LOCK(); OR ptr sequences found
    $seqPos = $pos;
    foreach (LOCK_OR_PTR_SEQs as $idx => $seq) {
        $find = findSequenceWithWildcard($fp, $seq, $seqPos, LOCK_OR_LOOK_AHEAD);
        if ($find === -1) {
            break; //Seq not found - there's no point to look further
        }

        $orsPos[] = $find;
        ++$orsPosNum;
        $seqPos = $find + LOCK_OR_PTR_SEQ_LEN; //Next search will start after the current sequence code
    }

    //We can always move forward by the function token length (obvious) but if we couldn't find any LOCK-OR tokens
    // we can skip the whole look ahead distance. We CANNOT do that if we found even a single token because the next one
    // might have been just after the look ahead distance
    if ($orsPosNum !== LOCK_OR_PTR_SEQs_NUM) {
        $pos += PUSH_R12_R15_SEQ_LEN;
        if ($orsPosNum === 0) {
            $pos += LOCK_OR_LOOK_AHEAD;
        }
        continue; //Continue the main search loop to find next function candidate
    }

    //We found LOCK(); OR ptr sequences so we can print some logs and collect ptrs (as this is quite expensive)
    $seqPtrsDist = [];
    perr("\n[?] Found possible f() @ " . decTo32bUFhex($pos) . "\n");
    $ptrOffset = null;
    $equalJumps = 0;
    foreach (LOCK_OR_PTR_SEQs as $idx => $seq) {
        //data will have the following bytes:
        // [0-LOCK()] [1-OR()] [2-BYTE-PTR] [3-OFFS-b3] [4-OFFS-b2] [5-OFFS-b1] [6-OFFS-b1] [7-NUMBER]
        $seqData = readAt($fp, $orsPos[$idx], LOCK_OR_PTR_SEQ_LEN);
        $newPtrOffset = //how far it "jumps"
            $orsPos[$idx] +
            (unpack('V', $seqData[3] . $seqData[4] . $seqData[5] . $seqData[6])[1]); //u32 bit LE

        if($ptrOffset === null) {
            $ptrOffset = $newPtrOffset; //Save the first one to compare in the next loop
            ++$equalJumps;
        } elseif ($ptrOffset === $newPtrOffset) {
            ++$equalJumps;
        }

        perr(
            "\t[+] Found LOCK-OR#$idx sequence @ " . decTo32bUFhex($orsPos[$idx]) . " => " .
            rawToUFhex($seqData) . " [RIP+(dec)$newPtrOffset]\n"
        );
    }
    if ($equalJumps !== 4) {
        perr("\t[-] LOCK-OR PTR offset mismatch - $equalJumps/" . LOCK_OR_PTR_SEQs_NUM . " matched\n");
        //If the pointer checking failed we can at least move beyond the last LOCK-OR found as we know there's no valid
        // sequence of LOCK-ORs there
        $pos = $orsPos[3];
        continue;
    }

    perr("\t[+] All $equalJumps LOCK-OR PTR offsets equal - match found!\n");
    break;
} while(!feof($fp));

if ($orsPos === null) { //There's a small chance no candidates with LOCK ORs were found
    perr("Failed to find matching sequences", true);
}

//Patch offsets
foreach ($orsPos as $seqFileOffset) {
    //The offset will point at LOCK(), we need to change the OR (0x80 0x0d) to AND (0x80 0x25) so the two bytes after
    $seqFileOffset = $seqFileOffset+2;

    perr("Patching OR to AND @ file offset (dec)$seqFileOffset\n");
    fseek($fp, $seqFileOffset);
    fwrite($fp, "\x25"); //0x0d is OR, 0x25 is AND
}

if (!isset($argv[2])) {
    perr("No output file specified - discarding data\n");
    exit;
}

saveStreamToFile($fp, $argv[2]);
fclose($fp);
