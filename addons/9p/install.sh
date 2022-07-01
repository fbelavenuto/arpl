if [ "${1}" = "rd" ]; then
  echo "Installing module for Plan 9 Resource Sharing Support (9P2000)"
  ${INSMOD} "/modules/9pnet.ko"
  ${INSMOD} "/modules/9pnet_virtio.ko"
  ${INSMOD} "/modules/9p.ko" ${PARAMS}
fi
