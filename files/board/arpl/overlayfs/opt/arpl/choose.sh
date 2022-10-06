#!/usr/bin/env bash

. /opt/arpl/include/functions.sh
. /opt/arpl/include/addons.sh
. /opt/arpl/include/modules.sh
. /opt/arpl/include/aioconsts.sh

# Check partition 3 space, if < 2GiB uses ramdisk
RAMCACHE=0
LOADER_DISK="`blkid | grep 'LABEL="ARPL3"' | cut -d3 -f1`"
LOADER_DEVICE_NAME=`echo ${LOADER_DISK} | sed 's|/dev/||'`
if [ `cat /sys/block/${LOADER_DEVICE_NAME}/${LOADER_DEVICE_NAME}3/size` -lt 4194304 ]; then
  RAMCACHE=1
fi

# Get actual IP
IP=`ip route get 1.1.1.1 2>/dev/null | awk '{print$7}'`

# Dirty flag
DIRTY=0

MODEL="`readConfigKey "model" "${USER_CONFIG_FILE}"`"
BUILD="`readConfigKey "build" "${USER_CONFIG_FILE}"`"
LAYOUT="`readConfigKey "layout" "${USER_CONFIG_FILE}"`"
KEYMAP="`readConfigKey "keymap" "${USER_CONFIG_FILE}"`"
LKM="`readConfigKey "lkm" "${USER_CONFIG_FILE}"`"
SN="`readConfigKey "sn" "${USER_CONFIG_FILE}"`"

###############################################################################
# Mounts backtitle dynamically
function backtitle() {
  BACKTITLE="Automated Redpill Loader ${ARPL_VERSION} - All in One"
  if [ -n "${MODEL}" ]; then
    BACKTITLE+=" ${MODEL}"
  else
    BACKTITLE+=" (no model)"
  fi
  if [ -n "${BUILD}" ]; then
    BACKTITLE+=" ${BUILD}"
  else
    BACKTITLE+=" (no build)"
  fi
  if [ -n "${SN}" ]; then
    BACKTITLE+=" ${SN}"
  else
    BACKTITLE+=" (no SN)"
  fi
  if [ -n "${IP}" ]; then
    BACKTITLE+=" ${IP}"
  else
    BACKTITLE+=" (no IP)"
  fi
  if [ -n "${KEYMAP}" ]; then
    BACKTITLE+=" (${LAYOUT}/${KEYMAP})"
  else
    BACKTITLE+=" (qwerty/us)"
  fi
  echo ${BACKTITLE}
}

###############################################################################
# Calls aio.sh to load the AiO Menu
function aiomenu() {
  aio.sh
}

###############################################################################
# Calls menu.sh to load the Full Menu
function classicmenu() {
  menu.sh
}

###############################################################################
###############################################################################

# Main loop
NEXT="m"
while true; do
  echo "- \"========== Main ========== \" "                                                 > "${TMP_PATH}/menu"
  echo "m \"AiO Build Menu\" "                                                              >> "${TMP_PATH}/menu"
  echo "n \"Classic Build Menu\" "                                                          >> "${TMP_PATH}/menu"
  echo "e \"Exit\" "                                                                        >> "${TMP_PATH}/menu"
  dialog --clear --default-item ${NEXT} --backtitle "`backtitle`" --colors \
    --menu "Choose the option" 0 0 0 --file "${TMP_PATH}/menu" \
    2>${TMP_PATH}/resp
  [ $? -ne 0 ] && break
  case `<"${TMP_PATH}/resp"` in
    m) aiomenu ;;
    n) classicmenu ;;
    e) break ;;
  esac
done
clear
echo -e "Call \033[1;32mchoose.sh\033[0m to return to menu"