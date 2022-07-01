if [ "${1}" = "rd" ]; then
  echo "Installing module(s) for ehci-pci"
  ${INSMOD} "/modules/pci-quirks.ko"
  ${INSMOD} "/modules/ehci-hcd.ko"
  ${INSMOD} "/modules/ehci-pci.ko" ${PARAMS}
fi
