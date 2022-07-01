if [ "${1}" = "rd" ]; then
  echo "Installing modules for ehci-pci"
  ${INSMOD} "/modules/ehci-hcd.ko"
  ${INSMOD} "/modules/ehci-pci.ko" ${PARAMS}
fi
