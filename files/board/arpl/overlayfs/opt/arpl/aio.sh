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
# Make Model Config

function sataconf() {
echo "Make DS3622xs+ SATA config"
    writeConfigKey "model" "${MODEL_AIO}" "${USER_CONFIG_FILE}"
    writeConfigKey "build" "${BUILD_AIO}" "${USER_CONFIG_FILE}"
    writeConfigKey "sn" "${SN_AIO}" "${USER_CONFIG_FILE}"
    deleteConfigKey "cmdline.SataPortMap"       "${USER_CONFIG_FILE}"
      # Check id model is compatible with CPU
      COMPATIBLE=1
      if [ ${RESTRICT} -eq 1 ]; then
        for F in `readModelArray "${M}" "flags"`; do
          if ! grep -q "^flags.*${F}.*" /proc/cpuinfo; then
            COMPATIBLE=0
            FLGNEX=1
            break
          fi
        done
      fi
echo "DS3622xs+ SATA config complete" && netconf
}

function scsiconf() {
echo "Make DS3622xs+ SCSI/SAS config"
    writeConfigKey "model" "${MODEL_AIO}" "${USER_CONFIG_FILE}"
    writeConfigKey "build" "${BUILD_AIO}" "${USER_CONFIG_FILE}"
    writeConfigKey "sn" "${SN_AIO}" "${USER_CONFIG_FILE}"
    writeConfigKey "cmdline.SataPortMap" "1"       "${USER_CONFIG_FILE}"
      # Check id model is compatible with CPU
      COMPATIBLE=1
      if [ ${RESTRICT} -eq 1 ]; then
        for F in `readModelArray "${M}" "flags"`; do
          if ! grep -q "^flags.*${F}.*" /proc/cpuinfo; then
            COMPATIBLE=0
            FLGNEX=1
            break
          fi
        done
      fi
echo "DS3622xs+ SCSI/SAS config complete" && netconf
}

###############################################################################
# Make Network Config

function netconf() {
echo "Make Network Config"
  lshw -class network -short > "${TMP_PATH}/netconf"
  if grep -R "eth0" "${TMP_PATH}/netconf"
  then
    if grep -R "eth1" "${TMP_PATH}/netconf"
    then
      if grep -R "eth2" "${TMP_PATH}/netconf"
      then
        if grep -R "eth3" "${TMP_PATH}/netconf"
        then
          echo "4 Network Adapter found"
          writeConfigKey "cmdline.mac1"      "${MAC1_AIO}" "${USER_CONFIG_FILE}"
          writeConfigKey "cmdline.mac2"      "${MAC2_AIO}" "${USER_CONFIG_FILE}"
          writeConfigKey "cmdline.mac3"      "${MAC3_AIO}" "${USER_CONFIG_FILE}"
          writeConfigKey "cmdline.mac4"      "${MAC4_AIO}" "${USER_CONFIG_FILE}"
          writeConfigKey "cmdline.netif_num" "4"           "${USER_CONFIG_FILE}"
        else
          echo "3 Network Adapter found"
          writeConfigKey "cmdline.mac1"      "${MAC1_AIO}" "${USER_CONFIG_FILE}"
          writeConfigKey "cmdline.mac2"      "${MAC2_AIO}" "${USER_CONFIG_FILE}"
          writeConfigKey "cmdline.mac3"      "${MAC3_AIO}" "${USER_CONFIG_FILE}"
          writeConfigKey "cmdline.netif_num" "3"           "${USER_CONFIG_FILE}"
        fi
      else
        echo "2 Network Adapter found"
        writeConfigKey "cmdline.mac1"      "${MAC1_AIO}" "${USER_CONFIG_FILE}"
        writeConfigKey "cmdline.mac2"      "${MAC2_AIO}" "${USER_CONFIG_FILE}"
        writeConfigKey "cmdline.netif_num" "2"           "${USER_CONFIG_FILE}"
      fi
    else
      echo "1 Network Adapter found"
      writeConfigKey "cmdline.mac1"      "${MAC1_AIO}" "${USER_CONFIG_FILE}"
      writeConfigKey "cmdline.netif_num" "1"           "${USER_CONFIG_FILE}"
    fi
  else
    echo " No Network Adapter found"
  fi
  MAC="${MAC1_AIO:0:2}:${MAC1_AIO:2:2}:${MAC1_AIO:4:2}:${MAC1_AIO:6:2}:${MAC1_AIO:8:2}:${MAC1_AIO:10:2}"
  ip link set dev eth0 address ${MAC} 2>&1 | dialog --backtitle "`backtitle`" \
    --title "Load AiO MAC" --progressbox "Changing MAC" 20 70
  /etc/init.d/S41dhcpcd restart 2>&1 | dialog --backtitle "`backtitle`" \
    --title "Load AiO MAC" --progressbox "Renewing IP" 20 70
  IP=`ip route get 1.1.1.1 2>/dev/null | awk '{print$7}'`
echo "Network Adapter config complete" && build
}

###############################################################################
# Adding Synoinfo and Addons

function build() {
  ITEMS="`readConfigEntriesArray "builds" "${MODEL_CONFIG_PATH}/${MODEL}.yml" | sort -r`"
  dialog --clear --no-items --backtitle "`backtitle`" \
    # Delete synoinfo and reload model/build synoinfo
    writeConfigKey "synoinfo" "{}" "${USER_CONFIG_FILE}"
    while IFS="=" read KEY VALUE; do
      writeConfigKey "synoinfo.${KEY}" "${VALUE}" "${USER_CONFIG_FILE}"
    done < <(readModelMap "${MODEL_AIO}" "builds.${BUILD_AIO}.synoinfo")
    # Check addons
    PLATFORM="`readModelKey "${MODEL_AIO}" "platform"`"
    KVER="`readModelKey "${MODEL_AIO}" "builds.${BUILD_AIO}.kver"`"
    while IFS="=" read ADDON PARAM; do
      [ -z "${ADDON}" ] && continue
      if ! checkAddonExist "${ADDON}" "${PLATFORM}" "${KVER}"; then
        deleteConfigKey "addons.${ADDON}" "${USER_CONFIG_FILE}"
      fi
    done < <(readConfigMap "addons" "${USER_CONFIG_FILE}")
    # Rebuild modules
    writeConfigKey "modules" "{}" "${USER_CONFIG_FILE}"
    while read ID DESC; do
      writeConfigKey "modules.${ID}" "" "${USER_CONFIG_FILE}"
    done < <(getAllModules "${PLATFORM}" "${KVER}")
    # Remove old files
    rm -f "${ORI_ZIMAGE_FILE}" "${ORI_RDGZ_FILE}" "${MOD_ZIMAGE_FILE}" "${MOD_RDGZ_FILE}"
    DIRTY=1
    echo "Build config complete" && make
}

###############################################################################
# Extracting DSM for building Loader

function extractDsmFiles() {
  PAT_URL="`readModelKey "${MODEL_AIO}" "builds.${BUILD_AIO}.pat.url"`"
  PAT_HASH="`readModelKey "${MODEL_AIO}" "builds.${BUILD_AIO}.pat.hash"`"
  RAMDISK_HASH="`readModelKey "${MODEL_AIO}" "builds.${BUILD_AIO}.pat.ramdisk-hash"`"
  ZIMAGE_HASH="`readModelKey "${MODEL_AIO}" "builds.${BUILD_AIO}.pat.zimage-hash"`"

  if [ ${RAMCACHE} -eq 0 ]; then
    OUT_PATH="${CACHE_PATH}/dl"
    echo "Cache in disk"
  else
    OUT_PATH="${TMP_PATH}/dl"
    echo "Cache in ram"
  fi
  mkdir -p "${OUT_PATH}"

  PAT_FILE="${MODEL_AIO}-${BUILD_AIO}.pat"
  PAT_PATH="${OUT_PATH}/${PAT_FILE}"
  EXTRACTOR_PATH="${CACHE_PATH}/extractor"
  EXTRACTOR_BIN="syno_extract_system_patch"
  OLDPAT_URL="https://global.download.synology.com/download/DSM/release/7.0.1/42218/DSM_DS3622xs%2B_42218.pat"
  OLDPAT_PATH="${OUT_PATH}/DS3622xs+-42218.pat"

  if [ -f "${PAT_PATH}" ]; then
    echo "${PAT_FILE} cached."
  else
    echo "Downloading ${PAT_FILE}"
    STATUS=`curl --insecure -w "%{http_code}" -L "${PAT_URL}" -o "${PAT_PATH}" --progress-bar`
    if [ $? -ne 0 -o ${STATUS} -ne 200 ]; then
      dialog --backtitle "`backtitle`" --title "Error downloading" --aspect 18 \
        --msgbox "Check internet or cache disk space" 0 0
      return 1
    fi
  fi

  echo -n "Checking hash of ${PAT_FILE}: "
  if [ "`sha256sum ${PAT_PATH} | awk '{print$1}'`" != "${PAT_HASH}" ]; then
    dialog --backtitle "`backtitle`" --title "Error" --aspect 18 \
      --msgbox "Hash of pat not match, try again!" 0 0
    rm -f ${PAT_PATH}
    return 1
  fi
  echo "OK"

  rm -rf "${UNTAR_PAT_PATH}"
  mkdir "${UNTAR_PAT_PATH}"
  echo -n "Disassembling ${PAT_FILE}: "

  header="$(od -bcN2 ${PAT_PATH} | head -1 | awk '{print $3}')"
  case ${header} in
    105)
      echo "Uncompressed tar"
      isencrypted="no"
      ;;
    213)
      echo "Compressed tar"
      isencrypted="no"
      ;;
    255)
      echo "Encrypted"
      isencrypted="yes"
      ;;
    *)
      dialog --backtitle "`backtitle`" --title "Error" --aspect 18 \
        --msgbox "Could not determine if pat file is encrypted or not, maybe corrupted, try again!" \
        0 0
      return 1
      ;;
  esac

  if [ "${isencrypted}" = "yes" ]; then
    # Check existance of extractor
    if [ -f "${EXTRACTOR_PATH}/${EXTRACTOR_BIN}" ]; then
      echo "Extractor cached."
    else
      # Extractor not exists, get it.
      mkdir -p "${EXTRACTOR_PATH}"
      # Check if old pat already downloaded
      if [ ! -f "${OLDPAT_PATH}" ]; then
        echo "Downloading old pat to extract synology .pat extractor..."
        STATUS=`curl --insecure -w "%{http_code}" -L "${OLDPAT_URL}" -o "${OLDPAT_PATH}"  --progress-bar`
        if [ $? -ne 0 -o ${STATUS} -ne 200 ]; then
          dialog --backtitle "`backtitle`" --title "Error downloading" --aspect 18 \
            --msgbox "Check internet or cache disk space" 0 0
          return 1
        fi
      fi
      # Extract ramdisk from PAT
      rm -rf "${RAMDISK_PATH}"
      mkdir -p "${RAMDISK_PATH}"
      tar -xf "${OLDPAT_PATH}" -C "${RAMDISK_PATH}" rd.gz >"${LOG_FILE}" 2>&1
      if [ $? -ne 0 ]; then
        dialog --backtitle "`backtitle`" --title "Error extracting" --textbox "${LOG_FILE}" 0 0
      fi

      # Extract all files from rd.gz
      (cd "${RAMDISK_PATH}"; xz -dc < rd.gz | cpio -idm) >/dev/null 2>&1 || true
      # Copy only necessary files
      for f in libcurl.so.4 libmbedcrypto.so.5 libmbedtls.so.13 libmbedx509.so.1 libmsgpackc.so.2 libsodium.so libsynocodesign-ng-virtual-junior-wins.so.7; do
        cp "${RAMDISK_PATH}/usr/lib/${f}" "${EXTRACTOR_PATH}"
      done
      cp "${RAMDISK_PATH}/usr/syno/bin/scemd" "${EXTRACTOR_PATH}/${EXTRACTOR_BIN}"
      rm -rf "${RAMDISK_PATH}"
    fi
    # Uses the extractor to untar pat file
    echo "Extracting..."
    LD_LIBRARY_PATH=${EXTRACTOR_PATH} "${EXTRACTOR_PATH}/${EXTRACTOR_BIN}" "${PAT_PATH}" "${UNTAR_PAT_PATH}" || true
  else
    echo "Extracting..."
    tar -xf "${PAT_PATH}" -C "${UNTAR_PAT_PATH}" >"${LOG_FILE}" 2>&1
    if [ $? -ne 0 ]; then
      dialog --backtitle "`backtitle`" --title "Error extracting" --textbox "${LOG_FILE}" 0 0
    fi
  fi

  echo -n "Checking hash of zImage: "
  HASH="`sha256sum ${UNTAR_PAT_PATH}/zImage | awk '{print$1}'`"
  if [ "${HASH}" != "${ZIMAGE_HASH}" ]; then
    sleep 1
    dialog --backtitle "`backtitle`" --title "Error" --aspect 18 \
      --msgbox "Hash of zImage not match, try again!" 0 0
    return 1
  fi
  echo "OK"
  writeConfigKey "zimage-hash" "${ZIMAGE_HASH}" "${USER_CONFIG_FILE}"

  echo -n "Checking hash of ramdisk: "
  HASH="`sha256sum ${UNTAR_PAT_PATH}/rd.gz | awk '{print$1}'`"
  if [ "${HASH}" != "${RAMDISK_HASH}" ]; then
    sleep 1
    dialog --backtitle "`backtitle`" --title "Error" --aspect 18 \
      --msgbox "Hash of ramdisk not match, try again!" 0 0
    return 1
  fi
  echo "OK"
  writeConfigKey "ramdisk-hash" "${RAMDISK_HASH}" "${USER_CONFIG_FILE}"

  echo -n "Copying files: "
  cp "${UNTAR_PAT_PATH}/grub_cksum.syno" "${BOOTLOADER_PATH}"
  cp "${UNTAR_PAT_PATH}/GRUB_VER"        "${BOOTLOADER_PATH}"
  cp "${UNTAR_PAT_PATH}/grub_cksum.syno" "${SLPART_PATH}"
  cp "${UNTAR_PAT_PATH}/GRUB_VER"        "${SLPART_PATH}"
  cp "${UNTAR_PAT_PATH}/zImage"          "${ORI_ZIMAGE_FILE}"
  cp "${UNTAR_PAT_PATH}/rd.gz"           "${ORI_RDGZ_FILE}"
  echo "DSM extract complete"
}

###############################################################################
# Building Loader

function make() {
  clear
  PLATFORM="`readModelKey "${MODEL_AIO}" "platform"`"
  KVER="`readModelKey "${MODEL_AIO}" "builds.${BUILD_AIO}.kver"`"

  # Check if all addon exists
  while IFS="=" read ADDON PARAM; do
    [ -z "${ADDON}" ] && continue
    if ! checkAddonExist "${ADDON}" "${PLATFORM}" "${KVER}"; then
      dialog --backtitle "`backtitle`" --title "Error" --aspect 18 \
        --msgbox "Addon ${ADDON} not found!" 0 0
      return 1
    fi
  done < <(readConfigMap "addons" "${USER_CONFIG_FILE}")

  [ ! -f "${ORI_ZIMAGE_FILE}" -o ! -f "${ORI_RDGZ_FILE}" ] && extractDsmFiles

  /opt/arpl/zimage-patch.sh
  if [ $? -ne 0 ]; then
    dialog --backtitle "`backtitle`" --title "Error" --aspect 18 \
      --msgbox "zImage not patched:\n`<"${LOG_FILE}"`" 0 0
    return 1
  fi

  /opt/arpl/ramdisk-patch.sh
  if [ $? -ne 0 ]; then
    dialog --backtitle "`backtitle`" --title "Error" --aspect 18 \
      --msgbox "Ramdisk not patched:\n`<"${LOG_FILE}"`" 0 0
    return 1
  fi

  echo "Cleaning"
  rm -rf "${UNTAR_PAT_PATH}"

  echo "Ready!"
  sleep 3
  DIRTY=0
  return 0
}

###############################################################################
# Calls boot.sh to boot into DSM kernel/ramdisk
function boot() {
  [ ${DIRTY} -eq 1 ] && dialog --backtitle "`backtitle`" --title "Alert" \
    --yesno "Config changed, would you like to rebuild the loader?" 0 0
  if [ $? -eq 0 ]; then
    make || return
  fi
  boot.sh
}

###############################################################################
# Calls menu.sh to load the Full Menu
function menu() {
  menu.sh
}

###############################################################################
# Permits user edit the user config
function editUserConfig() {
  while true; do
    dialog --backtitle "`backtitle`" --title "Edit with caution" \
      --editbox "${USER_CONFIG_FILE}" 0 0 2>"${TMP_PATH}/userconfig"
    [ $? -ne 0 ] && return
    mv "${TMP_PATH}/userconfig" "${USER_CONFIG_FILE}"
    ERRORS=`yq eval "${USER_CONFIG_FILE}" 2>&1`
    [ $? -eq 0 ] && break
    dialog --backtitle "`backtitle`" --title "Invalid YAML format" --msgbox "${ERRORS}" 0 0
  done
  OLDMODEL=${MODEL_AIO}
  OLDBUILD=${BUILD_AIO}
  MODEL="`readConfigKey "model" "${USER_CONFIG_FILE}"`"
  BUILD="`readConfigKey "build" "${USER_CONFIG_FILE}"`"
  SN="`readConfigKey "sn" "${USER_CONFIG_FILE}"`"
  if [ "${MODEL}" != "${OLDMODEL}" -o "${BUILD}" != "${OLDBUILD}" ]; then
    # Remove old files
    rm -f "${MOD_ZIMAGE_FILE}"
    rm -f "${MOD_RDGZ_FILE}"
  fi
  DIRTY=1
}

###############################################################################
# Shows available Drives
function alldrives() {
        TEXT=""
        NUMPORTS=0
        for PCI in `lspci -d ::106 | awk '{print$1}'`; do
          NAME=`lspci -s "${PCI}" | sed "s/\ .*://"`
          TEXT+="\Zb${NAME}\Zn\nPorts: "
          unset HOSTPORTS
          declare -A HOSTPORTS
          while read LINE; do
            ATAPORT="`echo ${LINE} | grep -o 'ata[0-9]*'`"
            PORT=`echo ${ATAPORT} | sed 's/ata//'`
            HOSTPORTS[${PORT}]=`echo ${LINE} | grep -o 'host[0-9]*$'`
          done < <(ls -l /sys/class/scsi_host | fgrep "${PCI}")
          while read PORT; do
            ls -l /sys/block | fgrep -q "${PCI}/ata${PORT}" && ATTACH=1 || ATTACH=0
            PCMD=`cat /sys/class/scsi_host/${HOSTPORTS[${PORT}]}/ahci_port_cmd`
            [ "${PCMD}" = "0" ] && DUMMY=1 || DUMMY=0
            [ ${ATTACH} -eq 1 ] && TEXT+="\Z2\Zb"
            [ ${DUMMY} -eq 1 ] && TEXT+="\Z1"
            TEXT+="${PORT}\Zn "
            NUMPORTS=$((${NUMPORTS}+1))
          done < <(echo ${!HOSTPORTS[@]} | tr ' ' '\n' | sort -n)
          TEXT+="\n"
        done
        TEXT+="\nTotal of ports: ${NUMPORTS}\n"
        TEXT+="\nPorts with color \Z1red\Zn as DUMMY, color \Z2\Zbgreen\Zn has drive connected."
        dialog --backtitle "`backtitle`" --colors --aspect 18 \
          --msgbox "${TEXT}" 0 0
}

###############################################################################
# Permit user select the modules to include
function selectModules() {
  PLATFORM="`readModelKey "${MODEL_AIO}" "platform"`"
  KVER="`readModelKey "${MODEL_AIO}" "builds.${BUILD_AIO}.kver"`"
  dialog --backtitle "`backtitle`" --title "Modules" --aspect 18 \
    --infobox "Reading modules" 0 0
  ALLMODULES=`getAllModules "${PLATFORM}" "${KVER}"`
  unset USERMODULES
  declare -A USERMODULES
  while IFS="=" read KEY VALUE; do
    [ -n "${KEY}" ] && USERMODULES["${KEY}"]="${VALUE}"
  done < <(readConfigMap "modules" "${USER_CONFIG_FILE}")
  # menu loop
  while true; do
    dialog --backtitle "`backtitle`" --menu "Choose a option" 0 0 0 \
      s "Show selected modules" \
      a "Select all modules" \
      d "Deselect all modules" \
      c "Choose modules to include" \
      e "Exit" \
      2>${TMP_PATH}/resp
    [ $? -ne 0 ] && break
    case "`<${TMP_PATH}/resp`" in
      s) ITEMS=""
        for KEY in ${!USERMODULES[@]}; do
          ITEMS+="${KEY}: ${USERMODULES[$KEY]}\n"
        done
        dialog --backtitle "`backtitle`" --title "User modules" \
          --msgbox "${ITEMS}" 0 0
        ;;
      a) dialog --backtitle "`backtitle`" --title "Modules" \
           --infobox "Selecting all modules" 0 0
        unset USERMODULES
        declare -A USERMODULES
        writeConfigKey "modules" "{}" "${USER_CONFIG_FILE}"
        while read ID DESC; do
          USERMODULES["${ID}"]=""
          writeConfigKey "modules.${ID}" "" "${USER_CONFIG_FILE}"
        done <<<${ALLMODULES}
        ;;

      d) dialog --backtitle "`backtitle`" --title "Modules" \
           --infobox "Deselecting all modules" 0 0
        writeConfigKey "modules" "{}" "${USER_CONFIG_FILE}"
        unset USERMODULES
        declare -A USERMODULES
        ;;

      c)
        rm -f "${TMP_PATH}/opts"
        while read ID DESC; do
          arrayExistItem "${ID}" "${!USERMODULES[@]}" && ACT="on" || ACT="off"
          echo "${ID} ${DESC} ${ACT}" >> "${TMP_PATH}/opts"
        done <<<${ALLMODULES}
        dialog --backtitle "`backtitle`" --title "Modules" --aspect 18 \
          --checklist "Select modules to include" 0 0 0 \
          --file "${TMP_PATH}/opts" 2>${TMP_PATH}/resp
        [ $? -ne 0 ] && continue
        resp=$(<${TMP_PATH}/resp)
        [ -z "${resp}" ] && continue
        dialog --backtitle "`backtitle`" --title "Modules" \
           --infobox "Writing to user config" 0 0
        unset USERMODULES
        declare -A USERMODULES
        writeConfigKey "modules" "{}" "${USER_CONFIG_FILE}"
        for ID in ${resp}; do
          USERMODULES["${ID}"]=""
          writeConfigKey "modules.${ID}" "" "${USER_CONFIG_FILE}"
        done
        ;;

      e)
        break
        ;;
    esac
  done
}

###############################################################################
# Shows available keymaps to user choose one
function keymapMenu() {
  dialog --backtitle "`backtitle`" --default-item "${LAYOUT}" --no-items \
    --menu "Choose a layout" 0 0 0 "azerty" "bepo" "carpalx" "colemak" \
    "dvorak" "fgGIod" "neo" "olpc" "qwerty" "qwertz" \
    2>${TMP_PATH}/resp
  [ $? -ne 0 ] && return
  LAYOUT="`<${TMP_PATH}/resp`"
  OPTIONS=""
  while read KM; do
    OPTIONS+="${KM::-7} "
  done < <(cd /usr/share/keymaps/i386/${LAYOUT}; ls *.map.gz)
  dialog --backtitle "`backtitle`" --no-items --default-item "${KEYMAP}" \
    --menu "Choice a keymap" 0 0 0 ${OPTIONS} \
    2>/tmp/resp
  [ $? -ne 0 ] && return
  resp=`cat /tmp/resp 2>/dev/null`
  [ -z "${resp}" ] && return
  KEYMAP=${resp}
  writeConfigKey "layout" "${LAYOUT}" "${USER_CONFIG_FILE}"
  writeConfigKey "keymap" "${KEYMAP}" "${USER_CONFIG_FILE}"
  zcat /usr/share/keymaps/i386/${LAYOUT}/${KEYMAP}.map.gz | loadkeys
}

###############################################################################
function updateMenu() {
  while true; do
    dialog --backtitle "`backtitle`" --menu "Choose a option" 0 0 0 \
      a "Update arpl" \
      d "Update addons" \
      l "Update LKMs" \
      m "Update modules" \
      e "Exit" \
      2>${TMP_PATH}/resp
    [ $? -ne 0 ] && return
    case "`<${TMP_PATH}/resp`" in
      a)
        dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
          --infobox "Checking last version" 0 0
        ACTUALVERSION="v${ARPL_VERSION}"
        TAG="`curl --insecure -s https://api.github.com/repos/AuxXxilium/arpl/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}'`"
        if [ $? -ne 0 -o -z "${TAG}" ]; then
          dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
            --msgbox "Error checking new version" 0 0
          continue
        fi
        if [ "${ACTUALVERSION}" = "${TAG}" ]; then
          dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
            --yesno "No new version. Actual version is ${ACTUALVERSION}\nForce update?" 0 0
          [ $? -ne 0 ] && continue
        fi
        dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
          --infobox "Downloading last version ${TAG}" 0 0
        # Download checksum
        STATUS=`curl --insecure -s -w "%{http_code}" -L "https://github.com/AuxXxilium/arpl/releases/download/${TAG}/sha256sum" -o /tmp/sha256sum`
        if [ $? -ne 0 -o ${STATUS} -ne 200 ]; then
          dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
            --msgbox "Error downloading checksums" 0 0
          continue
        fi
        STATUS=`curl --insecure -s -w "%{http_code}" -L "https://github.com/AuxXxilium/arpl/releases/download/${TAG}/bzImage" -o /tmp/bzImage`
        if [ $? -ne 0 -o ${STATUS} -ne 200 ]; then
          dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
            --msgbox "Error downloading bzImage" 0 0
          continue
        fi
        STATUS=`curl --insecure -s -w "%{http_code}" -L "https://github.com/AuxXxilium/arpl/releases/download/${TAG}/rootfs.cpio.xz" -o /tmp/rootfs.cpio.xz`
        if [ $? -ne 0 -o ${STATUS} -ne 200 ]; then
          dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
            --msgbox "Error downloading rootfs.cpio.xz" 0 0
          continue
        fi
        dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
          --infobox "Installing new files" 0 0
        (cd /tmp && sha256sum --status -c sha256sum)
        if [ $? -ne 0 ]; then
          dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
            --msgbox "Checksum do not match!" 0 0
          continue
        fi
        mv /tmp/bzImage "${ARPL_BZIMAGE_FILE}"
        mv /tmp/rootfs.cpio.xz "${ARPL_RAMDISK_FILE}"
        dialog --backtitle "`backtitle`" --title "Update arpl" --aspect 18 \
          --yesno "Arpl updated with success to ${TAG}!\nReboot?" 0 0
        [ $? -ne 0 ] && continue
        reboot
        exit
        ;;

      d)
        dialog --backtitle "`backtitle`" --title "Update addons" --aspect 18 \
          --infobox "Checking last version" 0 0
        TAG=`curl --insecure -s https://api.github.com/repos/AuxXxilium/arpl-addons/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}'`
        if [ $? -ne 0 -o -z "${TAG}" ]; then
          dialog --backtitle "`backtitle`" --title "Update addons" --aspect 18 \
            --msgbox "Error checking new version" 0 0
          continue
        fi
        dialog --backtitle "`backtitle`" --title "Update addons" --aspect 18 \
          --infobox "Downloading last version" 0 0
        STATUS=`curl --insecure -s -w "%{http_code}" -L "https://github.com/AuxXxilium/arpl-addons/releases/download/${TAG}/addons.zip" -o /tmp/addons.zip`
        if [ $? -ne 0 -o ${STATUS} -ne 200 ]; then
          dialog --backtitle "`backtitle`" --title "Update addons" --aspect 18 \
            --msgbox "Error downloading new version" 0 0
          continue
        fi
        dialog --backtitle "`backtitle`" --title "Update addons" --aspect 18 \
          --infobox "Extracting last version" 0 0
        rm -rf /tmp/addons
        mkdir -p /tmp/addons
        unzip /tmp/addons.zip -d /tmp/addons >/dev/null 2>&1
        dialog --backtitle "`backtitle`" --title "Update addons" --aspect 18 \
          --infobox "Installing new addons" 0 0
        for PKG in `ls /tmp/addons/*.addon`; do
          ADDON=`basename ${PKG} | sed 's|.addon||'`
          rm -rf "${ADDONS_PATH}/${ADDON}"
          mkdir -p "${ADDONS_PATH}/${ADDON}"
          tar xaf "${PKG}" -C "${ADDONS_PATH}/${ADDON}" >/dev/null 2>&1
        done
        DIRTY=1
        dialog --backtitle "`backtitle`" --title "Update addons" --aspect 18 \
          --msgbox "Addons updated with success!" 0 0
        ;;

      l)
        dialog --backtitle "`backtitle`" --title "Update LKMs" --aspect 18 \
          --infobox "Checking last version" 0 0
        TAG=`curl --insecure -s https://api.github.com/repos/AuxXxilium/redpill-lkm/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}'`
        if [ $? -ne 0 -o -z "${TAG}" ]; then
          dialog --backtitle "`backtitle`" --title "Update LKMs" --aspect 18 \
            --msgbox "Error checking new version" 0 0
          continue
        fi
        dialog --backtitle "`backtitle`" --title "Update LKMs" --aspect 18 \
          --infobox "Downloading last version" 0 0
        STATUS=`curl --insecure -s -w "%{http_code}" -L "https://github.com/AuxXxilium/redpill-lkm/releases/download/${TAG}/rp-lkms.zip" -o /tmp/rp-lkms.zip`
        if [ $? -ne 0 -o ${STATUS} -ne 200 ]; then
          dialog --backtitle "`backtitle`" --title "Update LKMs" --aspect 18 \
            --msgbox "Error downloading last version" 0 0
          continue
        fi
        dialog --backtitle "`backtitle`" --title "Update LKMs" --aspect 18 \
          --infobox "Extracting last version" 0 0
        rm -rf "${LKM_PATH}/"*
        unzip /tmp/rp-lkms.zip -d "${LKM_PATH}" >/dev/null 2>&1
        DIRTY=1
        dialog --backtitle "`backtitle`" --title "Update LKMs" --aspect 18 \
          --msgbox "LKMs updated with success!" 0 0
        ;;
      m)
        unset PLATFORMS
        declare -A PLATFORMS
        while read M; do
          M="`basename ${M}`"
          M="${M::-4}"
          P=`readModelKey "${M}" "platform"`
          ITEMS="`readConfigEntriesArray "builds" "${MODEL_CONFIG_PATH}/${M}.yml"`"
          for B in ${ITEMS}; do
            KVER=`readModelKey "${M}" "builds.${B}.kver"`
            PLATFORMS["${P}-${KVER}"]=""
          done
        done < <(find "${MODEL_CONFIG_PATH}" -maxdepth 1 -name \*.yml | sort)
        dialog --backtitle "`backtitle`" --title "Update Modules" --aspect 18 \
          --infobox "Checking last version" 0 0
        TAG=`curl --insecure -s https://api.github.com/repos/AuxXxilium/arpl-modules/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}'`
        if [ $? -ne 0 -o -z "${TAG}" ]; then
          dialog --backtitle "`backtitle`" --title "Update Modules" --aspect 18 \
            --msgbox "Error checking new version" 0 0
          continue
        fi
        for P in ${!PLATFORMS[@]}; do
          dialog --backtitle "`backtitle`" --title "Update Modules" --aspect 18 \
            --infobox "Downloading ${P} modules" 0 0
          STATUS=`curl --insecure -s -w "%{http_code}" -L "https://github.com/AuxXxilium/arpl-modules/releases/download/${TAG}/${P}.tgz" -o "/tmp/${P}.tgz"`
          if [ $? -ne 0 -o ${STATUS} -ne 200 ]; then
            dialog --backtitle "`backtitle`" --title "Update Modules" --aspect 18 \
              --msgbox "Error downloading ${P}.tgz" 0 0
            continue
          fi
          rm "${MODULES_PATH}/${P}.tgz"
          mv "/tmp/${P}.tgz" "${MODULES_PATH}/${P}.tgz"
        done
        DIRTY=1
        dialog --backtitle "`backtitle`" --title "Update Modules" --aspect 18 \
          --msgbox "Modules updated with success!" 0 0
        ;;
      e) return ;;
    esac
  done
}

###############################################################################
###############################################################################

if [ "x$1" = "xb" -a -n "${MODEL_AIO}" -a -n "${BUILD_AIO}" -a loaderIsConfigured ]; then
  make
  boot
fi
# Main loop
NEXT="m"
while true; do
  echo "- \"========== Main ========== \" "                                                 > "${TMP_PATH}/menu"
  echo "m \"AiO Build Intel/VM Sata\" "                                                     >> "${TMP_PATH}/menu"
  echo "n \"AiO Build Intel/VM SCSI/SAS\" "                                                 >> "${TMP_PATH}/menu"
  loaderIsConfigured && echo "b \"Boot the loader\" "                                       >> "${TMP_PATH}/menu"
  loaderIsConfigured && echo "d \"Fix Loader after DSM Update\" "                           >> "${TMP_PATH}/menu"
  echo "= \"========== More ========== \" "                                                 >> "${TMP_PATH}/menu"
  echo "g \"Show Drives\" "                                                                 >> "${TMP_PATH}/menu"
  echo "o \"Modules\""                                                                      >> "${TMP_PATH}/menu"
  echo "u \"Edit user config file manually\" "                                              >> "${TMP_PATH}/menu"
  echo "k \"Choose a keymap\" "                                                             >> "${TMP_PATH}/menu"
  [ ${RAMCACHE} -eq 0 -a -d "${CACHE_PATH}/dl" ] && echo "c \"Clean disk cache\""           >> "${TMP_PATH}/menu"
  echo "p \"Update menu\" "                                                                 >> "${TMP_PATH}/menu"
  echo "e \"Exit\" "                                                                        >> "${TMP_PATH}/menu"
  dialog --clear --default-item ${NEXT} --backtitle "`backtitle`" --colors \
    --menu "Choose the option" 0 0 0 --file "${TMP_PATH}/menu" \
    2>${TMP_PATH}/resp
  [ $? -ne 0 ] && break
  case `<"${TMP_PATH}/resp"` in
    m) sataconf; NEXT="b" ;;
    n) scsiconf; NEXT="b" ;;
    b) boot ;;
    d) make; NEXT="b" ;;
    g) alldrives ;;
    o) selectModules ;;
    u) editUserConfig ;;
    k) keymapMenu ;;
    c) dialog --backtitle "`backtitle`" --title "Cleaning" --aspect 18 \
      --prgbox "rm -rfv \"${CACHE_PATH}/dl\"" 0 0 ;;
    p) updateMenu ;;
    e) break ;;
  esac
done
clear
echo -e "Call \033[1;32maio.sh\033[0m to return to menu"