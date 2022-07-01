#!/usr/bin/env bash

. /opt/arpl/include/functions.sh

# Sanity check
[ -f "${ORI_ZIMAGE_FILE}" ] || die "${ORI_ZIMAGE_FILE} not found!"

echo -n "Patching zImage"

rm -f "${MOD_ZIMAGE_FILE}"
echo -n "."
# Extract vmlinux
/opt/arpl/bzImage-to-vmlinux.sh "${ORI_ZIMAGE_FILE}" "${TMP_PATH}/vmlinux" >"${LOG_FILE}" 2>&1 || dieLog
echo -n "."
# Patch boot params
/opt/arpl/patch-boot_params-check.php "${TMP_PATH}/vmlinux" "${TMP_PATH}/vmlinux-mod1" >"${LOG_FILE}" 2>&1 || dieLog
echo -n "."
# Patch ramdisk check
/opt/arpl/patch-ramdisk-check.php "${TMP_PATH}/vmlinux-mod1" "${TMP_PATH}/vmlinux-mod2" >"${LOG_FILE}" 2>&1 || dieLog
echo -n "."
# rebuild zImage
/opt/arpl/vmlinux-to-bzImage.sh "${TMP_PATH}/vmlinux-mod2" "${MOD_ZIMAGE_FILE}" >"${LOG_FILE}" 2>&1 || dieLog

echo -n "."
# Update HASH of new DSM zImage
HASH="`sha256sum ${ORI_ZIMAGE_FILE} | awk '{print$1}'`"
writeConfigKey "zimage-hash" "${HASH}" "${USER_CONFIG_FILE}"
echo
