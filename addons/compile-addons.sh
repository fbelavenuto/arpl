#!/usr/bin/env bash

set -e

TMP_PATH="/tmp"
DEST_PATH="../files/board/arpl/p3/addons"

###############################################################################
function trap_cancel() {
    echo "Press Control+C once more terminate the process (or wait 2s for it to restart)"
    sleep 2 || exit 1
}
trap trap_cancel SIGINT SIGTERM

###############################################################################
function die() {
  echo -e "\033[1;31m$@\033[0m"
  exit 1
}

###############################################################################
#
# 1 - Path of key
function hasConfigKey() {
  [ "`yq eval '.'${1}' | has("'${2}'")' "${3}"`" == "true" ] && return 0 || return 1
}

###############################################################################
# Read key value from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Return Value
function readConfigKey() {
  RESULT=`yq eval '.'${1}' | explode(.)' "${2}"`
  [ "${RESULT}" == "null" ] && echo "" || echo ${RESULT}
}

###############################################################################
# Read Entries as map(key=value) from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Returns map of values
function readConfigMap() {
  yq eval '.'${1}' | explode(.) | to_entries | map([.key, .value] | join("=")) | .[]' "${2}"
}

###############################################################################
# Read an array from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Returns array/map of values
function readConfigArray() {
  yq eval '.'${1} "${2}"
}

###############################################################################
# Read Entries as array from yaml config file
# 1 - Path of key
# 2 - Path of yaml config file
# Returns array of values
function readConfigEntriesArray() {
  yq eval '.'${1}' | explode(.) | to_entries | map([.key])[] | .[]' "${2}"
}


###############################################################################
function compile-addon() {
  MANIFEST="${1}/manifest.yml"
  [ ! -f "${MANIFEST}" ] && die "${MANIFEST} not found"
  echo -e "\033[7mProcessing manifest ${MANIFEST}\033[0m"
  OUT_PATH="${TMP_PATH}/${1}"
  rm -rf "${OUT_PATH}"
  mkdir -p "${OUT_PATH}"
  VER=`readConfigKey "version" "${MANIFEST}"`
  [ ${VER} -ne 1 ] && die "Error, version ${VER} of manifest not suported"
  cp "${MANIFEST}" "${OUT_PATH}"
  # Check if exist files for all platforms
  if hasConfigKey "" "all" "${MANIFEST}"; then
    echo -e "\033[1;32m Processing 'all' section\033[0m"
    mkdir -p "${OUT_PATH}/all/root"
    HAS_FILES=0
    # Get name of script to install, if defined. This script has low priority
    INSTALL_SCRIPT="`readConfigKey "all.install-script" "${MANIFEST}"`"
    if [ -n "${INSTALL_SCRIPT}" ]; then
      if [ -f "${1}/${INSTALL_SCRIPT}" ]; then
        echo -e "\033[1;35m  Copying install script ${INSTALL_SCRIPT}\033[0m"
        cp "${1}/${INSTALL_SCRIPT}" "${OUT_PATH}/all/install.sh"
        HAS_FILES=1
      else
        echo -e "\033[1;33m  WARNING: install script '${INSTALL_SCRIPT}' not found\033[0m"
      fi
    fi
    # Get folder name for copy
    COPY_PATH="`readConfigKey "all.copy" "${MANIFEST}"`"
    # If folder exists, copy
    if [ -n "${COPY_PATH}" ]; then
      if [ -d "${1}/${COPY_PATH}" ]; then
        echo -e "\033[1;35m  Copying folder '${COPY_PATH}'\033[0m"
        cp -R "${1}/${COPY_PATH}/"* "${OUT_PATH}/all/root"
        HAS_FILES=1
      else
        echo -e "\033[1;33m  WARNING: folder '${COPY_PATH}' not found\033[0m"
      fi
    fi
    if [ ${HAS_FILES} -eq 1 ]; then
      # Create tar gziped
      tar caf "${OUT_PATH}/all.tgz" -C "${OUT_PATH}/all" .
      echo -e "\033[1;36m  Created file '${OUT_PATH}/all.tgz' \033[0m"
    fi
    # Clean
    rm -rf "${OUT_PATH}/all"
  fi
  unset AVAL_FOR
  declare -a AVAL_FOR
  for P in `readConfigEntriesArray "available-for" "${MANIFEST}"`; do
    AVAL_FOR+=(${P})
  done
  [ ${#AVAL_FOR} -eq 0 ] && return

    # Loop in each available platform-kver
  for P in ${AVAL_FOR[@]}; do
    echo -e "\033[1;32m Processing '${P}' platform-kver section\033[0m"
    mkdir -p "${OUT_PATH}/${P}/root"
    HAS_FILES=0
    # Get name of script to install, if defined. This script has high priority
    INSTALL_SCRIPT="`readConfigKey 'available-for."'${P}'".install-script' "${MANIFEST}"`"
    if [ -n "${INSTALL_SCRIPT}" ]; then
      if [ -f "${1}/${INSTALL_SCRIPT}" ]; then
        echo -e "\033[1;35m  Copying install script ${INSTALL_SCRIPT}\033[0m"
        cp "${1}/${INSTALL_SCRIPT}" "${OUT_PATH}/${P}/install.sh"
        HAS_FILES=1
      else
        echo -e "\033[1;33m  WARNING: install script '${INSTALL_SCRIPT}' not found\033[0m"
      fi
    fi
    # Get folder name for copy
    COPY_PATH="`readConfigKey 'available-for."'${P}'".copy' "${MANIFEST}"`"
    # If folder exists, copy
    if [ -n "${COPY_PATH}" ]; then
      if [ -d "${1}/${COPY_PATH}" ]; then
        echo -e "\033[1;35m  Copying folder '${COPY_PATH}'\033[0m"
        cp -R "${1}/${COPY_PATH}/"* "${OUT_PATH}/${P}/root"
        HAS_FILES=1
      else
        echo -e "\033[1;33m  WARNING: folder '${COPY_PATH}' not found\033[0m"
      fi
    fi
    HAS_MODULES="`readConfigKey 'available-for."'${P}'".modules' "${MANIFEST}"`"
    # Check if has modules for compile
    if [ "${HAS_MODULES}" = "true" ]; then
      echo "Compiling modules"
      PLATFORM="`echo ${P} | cut -d'-' -f1`"
      KVER="`echo ${P} | cut -d'-' -f2`"
      # Compile using docker
      docker run --rm -t --user `id -u` -v "${TMP_PATH}":/output \
        -v "${PWD}/${1}/src/${KVER}":/input syno-compiler compile-module ${PLATFORM}
      mkdir -p "${OUT_PATH}/${P}/root/modules"
      mv "${TMP_PATH}/"*.ko "${OUT_PATH}/${P}/root/modules/"
      HAS_FILES=1
    fi
    if [ ${HAS_FILES} -eq 1 ]; then
      # Create tar gziped
      tar caf "${OUT_PATH}/${P}.tgz" -C "${OUT_PATH}/${P}" .
      echo -e "\033[1;36m  Created file '${P}.tgz' \033[0m"
    fi
    # Clean
    rm -rf "${OUT_PATH}/${P}"
  done
  # Update files for image
  rm -rf "${DEST_PATH}/${1}"
  mkdir -p "${DEST_PATH}/${1}"
  cp "${OUT_PATH}/"* "${DEST_PATH}/${1}/"
}

# Main
if [ $# -ge 1 ]; then
  for A in $@; do
    compile-addon ${A}
  done
else
  while read D; do
    DRIVER=`basename ${D}`
    [ "${DRIVER}" = "." ] && continue
    compile-addon ${DRIVER}
  done < <(find -maxdepth 1 -type d)
fi
