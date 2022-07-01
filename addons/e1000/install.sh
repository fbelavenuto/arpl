if [ "${1}" = "rd" ]; then
  echo "Installing module for Intel(R) PRO/1000 Gigabit Ethernet adapter"
  ${INSMOD} "/modules/e1000.ko" ${PARAMS}
fi
