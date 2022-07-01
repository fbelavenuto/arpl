if [ "${1}" = "rd" ]; then
  echo "Checking for VirtIO..."
  if (grep -r -q -E "(QEMU|VirtualBox)" /sys/devices/virtual/dmi/id/); then
    echo "VirtIO hypervisor detected!"
    ${INSMOD} "/modules/virtio.ko" ${PARAMS}
    ${INSMOD} "/modules/virtio_ring.ko" ${PARAMS}
    ${INSMOD} "/modules/virtio_mmio.ko" ${PARAMS}
    ${INSMOD} "/modules/virtio_pci.ko" ${PARAMS}
    ${INSMOD} "/modules/virtio_net.ko" ${PARAMS}
    ${INSMOD} "/modules/virtio_scsi.ko" ${PARAMS}
  else
    echo "No VirtIO hypervisor detected!"
  fi
fi
