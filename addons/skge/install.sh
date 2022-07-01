if [ "${1}" = "rd" ]; then
  echo "Installing module for Marvell Yukon Gigabit Ethernet adapter"
  ${INSMOD} "/modules/skge.ko" ${PARAMS}
fi
