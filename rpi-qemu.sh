#! /usr/bin/env bash

#  MacOS Mojave

# https://github.com/dhruvvyas90/qemu-rpi-kernel/
# https://gist.github.com/hfreire/5846b7aa4ac9209699ba#gistcomment-2953346

export QEMU=$(which qemu-system-arm)
export TMP_DIR=$HOME/prj-offline/yubikey/qemu-rasp-pi/TEST
export RPI_KERNEL=${TMP_DIR}/kernel-qemu-4.19.50-buster
export RPI_FS=${TMP_DIR}/2019-09-26-raspbian-buster-lite.img
export PTB_FILE=${TMP_DIR}/versatile-pb-buster.dtb
export IMAGE_FILE=2019-09-26-raspbian-buster-lite.zip
export IMAGE=http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-09-30/${IMAGE_FILE}

mkdir -p $TMP_DIR
cd $TMP_DIR

wget --progress=dot:mega "https://github.com/dhruvvyas90/qemu-rpi-kernel/blob/master/kernel-qemu-4.19.50-buster?raw=true" \
  -O "${RPI_KERNEL}"

wget --progress=dot "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb-buster.dtb" \
  -O "${PTB_FILE}"

wget --progress=dot:giga $IMAGE
unzip $IMAGE_FILE


$QEMU -kernel ${RPI_KERNEL} \
  -cpu arm1176 \
  -nographic \
  -m 256 \
  -M versatilepb \
  -dtb ${PTB_FILE} \
  -no-reboot \
  -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
  -drive "file=${RPI_FS},index=0,media=disk,format=raw" \
  -net user,hostfwd=tcp::5022-:22 \
  -net nic

  #-audiodev id=none,driver=none \
  #-nographic \
  #-serial stdio \
