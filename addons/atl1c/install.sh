if [ "${1}" = "rd" ]; then
  echo "Installing module for Atheros L1C Gigabit Ethernet adapter"
  ${INSMOD} "/modules/atl1c.ko" ${PARAMS}
fi
