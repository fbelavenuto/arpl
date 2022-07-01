#!/usr/bin/env php
<?php
declare(strict_types=1);

/**
 * This file contains usual common functions used by patchers
 *
 * Most of the functions here are written to be C-like without utilizing any of the PHP's magic. This functionality is
 * ultimately intended to be rewritten into a dynamic patcher in C. Making this code compatible wtih simple C (e.g.
 * by not using fancy regexes) will make it slower in PHP but MUCH easier to rewrite into C later on.
 */

function perr(string $txt, $die = false)
{
    fwrite(STDERR, $txt);
    if ($die) {
        die();
    }
}

/**
 * @return int
 */
function getELFSectionAddr(string $elf, string $section, int $pos)
{
    $secAddr = exec(
        sprintf('readelf -S \'%1$s\' | grep -E \'\s%2$s\s\' | awk -F\'%2$s\' \'{ print $2 }\' | awk \'{ print $%3$d }\'', $elf, str_replace('.', '\.', $section), $pos)
    );
    if (!$secAddr) {
        perr("$section section not found in $elf file\n", true);
    }

    $secAddr = hexdec(substr($secAddr, -8));
    perr("Found $section at " . decTo32bUFhex($secAddr) . " in $elf\n");

    return $secAddr;
}

function getELFStringLoc(string $elf, string $text)
{
    $strAddr = exec(
        sprintf(
            'readelf -p \'.rodata\' \'%s\' | grep \'%s\' | grep -oE \'\[(\s+)?.+\]\' | grep -oE \'[a-f0-9]+\'',
            $elf, $text
        )
    );

    if (!$strAddr) {
        perr("$text string not found in $elf file's .rodata section\n", true);
    }

    $secAddr = hexdec(substr($strAddr, -8));
    perr("Found \"$text\" at " . decTo32bUFhex($secAddr) . " in $elf\n");

    return $secAddr;
}

function getArgFilePath(int $argn)
{
    global $argv;

    $file = realpath($argv[$argn]);
    if (!is_file($file) || !$file) {
        perr("Expected a readable file in argument $argn - found none\n", true);
    }

    return $file;
}

/**
 * Converts decimal value to 32-bit little-endian hex value
 */
function decTo32bLEhex(int $dec)
{
    $hex = str_pad(dechex($dec), 32 / 8 * 2, 'f', STR_PAD_LEFT); //32-bit hex

    return implode('', array_reverse(str_split($hex, 2))); //make it little-endian
}

/**
 * Converts decimal value to 32-bit user-friendly (and big-endian) hex value
 *
 * This function should really be used for printing
 */
function decTo32bUFhex(int $dec)
{
    return implode(' ', str_split(str_pad(dechex($dec), 32 / 8 * 2, 'f', STR_PAD_LEFT), 2));
}

function rawToUFhex(string $raw)
{
    $out = '';
    for($i=0, $iMax = strlen($raw); $i < $iMax; $i++) {
        $out .=  sprintf('%02x', ord($raw[$i]));

        if ($i+1 !== $iMax) {
            $out .= ' ';
        }
    }

    return $out;
}

/**
 * Convert hex values to their binary/raw counterparts as-is
 */
function hex2raw(string $hex)
{
    $bin = '';
    for ($i = 0, $iMax = strlen($hex); $i < $iMax; $i += 2) {
        $bin .= chr(hexdec($hex[$i] . $hex[$i + 1]));
    }

    return $bin;
}

const DIR_FWD = 1;
const DIR_RWD = -1;
function findSequence($fp, string $bin, int $pos, int $dir, int $maxToCheck)
{
    if ($maxToCheck === -1) {
        $maxToCheck = PHP_INT_MAX;
    }

    $len = strlen($bin);
    do {
        fseek($fp, $pos);
        if (strcmp(fread($fp, $len), $bin) === 0) {
            return $pos;
        }

        $pos = $pos + $dir;
        $maxToCheck--;
    } while (!feof($fp) && $pos != -1 && $maxToCheck != 0);

    return -1;
}

/**
 * Locates a pattern of bytes $searchSeqNum in a $fp stream starting from $pos seeking up to $maxToCheck
 *
 * @param array $searchSeqNum An array containing n elements (where n=length of the searched sequence). Each element can
 *                            be a null (denoting "any byte"), singular hex/int value (e.g. 0xF5), or a range in a form
 *                            of a two-element array (e.g. [0xF0, 0xF7])
 */
function findSequenceWithWildcard($fp, array $searchSeqNum, int $pos, int $maxToCheck)
{
    if ($maxToCheck === -1) {
        $maxToCheck = PHP_INT_MAX;
    }

    $bufLen = count($searchSeqNum);
    if ($maxToCheck < $bufLen) {
        perr("maxToCheck cannot be smaller than search sequence!", true);
    }

    //Convert all singular value to raw bytes while leaving arrays as numeric (performance reasons). As this loop is
    //executed once per pattern it can be sub-optimal but more careful with data validation
    $searchSeq = [];
    foreach ($searchSeqNum as $idx => $num) {
        if ($num === null) {
            $searchSeq[] = null;
        } elseif (is_array($num) && count($num) == 2 && is_int($num[0]) && is_int($num[1]) && $num[0] >= 0 &&
                  $num[0] <= 255 && $num[1] >= 0 && $num[1] <= 255 && $num[0] < $num[1]) {
            $searchSeq[] = $num; //Leave them as numeric
        } elseif (is_int($num) && $num >= 0 && $num <= 255) {
            $searchSeq[] = chr($num);
        } else {
            perr("Found invalid search sequence at index $idx", true);
        }
    }

    //$pos denotes start position but it's also used to mark where start of a potential pattern match was found
    fseek($fp, $pos);
    do { //This loop is optimized for speed
        $buf = fread($fp, $bufLen);
        if (!isset($buf[$bufLen-1])) {
            break; //Not enough data = no match
        }

        $successfulLoops = 0;
        foreach ($searchSeq as $byteIdx => $seekByte) {
            if ($seekByte === null) { //any character
                ++$successfulLoops;
                continue;
            }

            //element in the array can be a range [(int)from,(int)to] or a literal SINGLE byte
            //if isset finds a second element it will mean for us that it's an array of 2 elements (as we don't expect
            //a string longer than a single byte)
            if (isset($seekByte[1])) {
                $curByteNum = ord($buf[$byteIdx]);
                if ($curByteNum < $seekByte[0] || $curByteNum > $seekByte[1]) {
                    break;
                }
            } elseif($buf[$byteIdx] !== $seekByte) { //If the byte doesn't match literally we know it's not a match
                break;
            }

            ++$successfulLoops;
        }
        if ($successfulLoops === $bufLen) {
            return $pos;
        }

        fseek($fp, ++$pos);
        $maxToCheck--;
    } while (!feof($fp) && $maxToCheck != 0);

    return -1;
}

/**
 * @return resource
 */
function getFileMemMapped(string $path)
{
    $fp = fopen('php://memory', 'r+');
    fwrite($fp, file_get_contents($path)); //poor man's mmap :D

    return $fp;
}

function saveStreamToFile($fp, string $path)
{
    perr("Saving stream to $path ...\n");

    $fp2 = fopen($path, 'w');
    fseek($fp, 0);
    while (!feof($fp)) {
        fwrite($fp2, fread($fp, 8192));
    }
    fclose($fp2);

    perr("DONE!\n");
}

/**
 * Do not call this in time-sensitive code...
 */
function readAt($fp, int $pos, int $len)
{
    fseek($fp, $pos);
    return fread($fp, $len);
}
