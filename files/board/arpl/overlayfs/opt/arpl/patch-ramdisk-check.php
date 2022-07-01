#!/usr/bin/env php
<?php
declare(strict_types=1);

/**
 * A quick tool for patching the ramdisk check in the DSM kernel image
 * This lets you tinker with the initial ramdisk contents without disabling mount() features and modules loading
 *
 * Usage: php patch-ramdisk-check.php vmlinux vmlinux-mod
 */

require __DIR__ . '/common.php';

if ($argc < 2 || $argc > 3) {
    perr("Usage: " . $argv[0] . " <inFile> [<outFile>]\n", true);
}

$file = getArgFilePath(1);
perr("\nGenerating patch for $file\n");

//Strings (e.g. error for printk()) reside in .rodata - start searching there to save time
$rodataAddr = getELFSectionAddr($file, '.rodata', 2);

//Locate the precise location of "ramdisk error" string
$rdErrAddr = getELFStringLoc($file, '3ramdisk corrupt');


//offsets will be 32 bit in ASM and in LE
$errPrintAddr = $rodataAddr + $rdErrAddr;
$errPrintCAddrLEH = decTo32bLEhex($errPrintAddr - 1); //Somehow rodata contains off-by-one sometimes...
$errPrintAddrLEH = decTo32bLEhex($errPrintAddr);
perr("LE arg addr: " . $errPrintCAddrLEH . "\n");

$fp = getFileMemMapped($file); //Read the whole file to memory to make fseet/fread much faster

//Find the printk() call argument
$printkPos = findSequence($fp, hex2raw($errPrintCAddrLEH), 0, DIR_FWD, -1);
if ($printkPos === -1) {
    perr("printk pos not found!\n", true);
}
perr("Found printk arg @ " . decTo32bUFhex($printkPos) . "\n");

//double check if it's a MOV reg,VAL (where reg is EAX/ECX/EDX/EBX/ESP/EBP/ESI/EDI)
fseek($fp, $printkPos - 3);
$instr = fread($fp, 3);
if (strncmp($instr, "\x48\xc7", 2) !== 0) {
    perr("Expected MOV=>reg before printk error, got " . bin2hex($instr) . "\n", true);
}
$dstReg = ord($instr[2]);
if ($dstReg < 192 || $dstReg > 199) {
    perr("Expected MOV w/reg operand [C0-C7], got " . bin2hex($instr[2]) . "\n", true);
}
$movPos = $printkPos - 3;
perr("Found printk MOV @ " . decTo32bUFhex($movPos) . "\n");

//now we should seek a reasonable amount (say, up to 32 bytes) for a sequence of CALL x => TEST EAX,EAX => JZ
$testPos = findSequence($fp, "\x85\xc0", $movPos, DIR_RWD, 32);
if ($testPos === -1) {
    perr("Failed to find TEST eax,eax\n", true);
}

$jzPos = $testPos + 2;
fseek($fp, $jzPos);
$jz = fread($fp, 2);
if ($jz[0] !== "\x74") {
    perr("Failed to find JZ\n", true);
}

$jzp = "\xEB" . $jz[1];
perr('OK - patching ' . bin2hex($jz) . " (JZ) to " . bin2hex($jzp) . " (JMP) @ $jzPos\n");
fseek($fp, $jzPos); //we should be here already
perr("Patched " . fwrite($fp, $jzp) . " bytes in memory\n");

if (!isset($argv[2])) {
    perr("No output file specified - discarding data\n");
    exit;
}

if (!isset($argv[2])) {
    perr("No output file specified - discarding data\n");
    exit;
}

saveStreamToFile($fp, $argv[2]);
fclose($fp);
