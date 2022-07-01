if [ "${1}" = "rd" ]; then
  echo "Installing module for RealTek RTL8125 2.5Gigabit PCI-e Ethernet adapter"
  ${INSMOD} "/modules/r8125.ko" ${PARAMS}
fi
