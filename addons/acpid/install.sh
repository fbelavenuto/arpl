if [ "${1}" = "sys" ]; then
  echo "Installing module and daemon for ACPI button"
  if [ ! -f /tmpRoot/lib/modules/button.ko ]; then
    cp /modules/button.ko /tmpRoot/lib/modules/
  fi
  tar -zxvf /addons/acpid.tgz -C /tmpRoot/
  chmod 755 /tmpRoot/usr/sbin/acpid
  chmod 644 /tmpRoot/etc/acpi/events/power
  chmod 744 /tmpRoot/etc/acpi/power.sh
  chmod 744 /tmpRoot/usr/lib/systemd/system/acpid.service
  ln -sf /usr/lib/systemd/system/acpid.service /tmpRoot/etc/systemd/system/multi-user.target.wants/acpid.service
fi
