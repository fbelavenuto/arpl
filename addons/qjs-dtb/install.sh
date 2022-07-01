if [ "${1}" = "rd" ]; then
  echo "Jumkey's qjs-dtb arpl version - ramdisk time"
  # fix executable flag
  chmod +x /usr/sbin/dtc
  chmod +x /usr/sbin/qjs

  # copy file
  if [ ! -f model_${PLATFORM_ID%%_*}.dtb ]; then
    # Dynamic generation
    dtc -I dtb -O dts -o output.dts /etc.defaults/model.dtb
    qjs --std /addons/dts.js output.dts output.dts.out
    if [ $? -ne 0 ]; then
      echo "auto generated dts file is broken"
    else
      dtc -I dts -O dtb -o model_r2.dtb output.dts.out
      cp -vf model_r2.dtb /etc.defaults/model.dtb
      cp -vf model_r2.dtb /var/run/model.dtb
    fi
  else
    cp -vf model_${PLATFORM_ID%%_*}.dtb /etc.defaults/model.dtb
    cp -vf model_${PLATFORM_ID%%_*}.dtb /var/run/model.dtb
  fi
else
  echo "Jumkey's qjs-dtb arpl version - sys time"
  # copy file
  cp -vf /etc.defaults/model.dtb /tmpRoot/etc.defaults/model.dtb
fi
