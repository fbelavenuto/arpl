if [ "${1}" = "rd" ]; then
  echo "Installing module for Atheros L1E Gigabit Ethernet adapter"
  ${INSMOD} "/modules/atl1e.ko" ${PARAMS}
fi
