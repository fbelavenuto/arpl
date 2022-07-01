#!/usr/bin/env bash
# CONFIG_DIR = .
# $1 = Target path = ./output/target
# BR2_DL_DIR = ./dl
# BINARIES_DIR = ./output/images
# BUILD_DIR = ./output/build
# BASE_DIR = ./output

set -e

# Fix DHCPCD client id
sed -i 's|#clientid|clientid|' "${1}/etc/dhcpcd.conf"
sed -i 's|duid|#duid|' "${1}/etc/dhcpcd.conf"
