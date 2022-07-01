#!/usr/bin/env php
<?php
if ($argc < 2 || $argc > 2) {
    fwrite(STDERR, "Usage: " . $argv[0] . " <file>\n");
    die();
}
echo hash_file('crc32b', $argv[1]);
?>
