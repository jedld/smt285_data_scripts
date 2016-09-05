echo "resetting sdcard"

if [ ! -d "/data/external" ]; then
  mkdir /data/external
fi

mount -t ext4 /dev/block/mmcblk1p1 /data/external
rm -rf /data/external/data
rm -rf /data/external/app
rm /data/scripts/vold.init/reset_card.sh
umount /data/external
rm -rf /data/external

echo "done removed self"
