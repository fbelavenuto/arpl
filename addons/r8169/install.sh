if [ "${1}" = "rd" ]; then
  echo "Installing module for Realtek R8169 Ethernet adapter"
  ${INSMOD} "/modules/mii.ko"
  ${INSMOD} "/modules/r8169.ko" ${PARAMS}
fi
