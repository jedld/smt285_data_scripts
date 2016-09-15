echo "resetting sdcard"

rm /data/scripts/vold.init/mount_ext4_sdcard.sh

if [ ! -d "/data/external" ]; then
  mkdir /data/external
fi

mount -t ext4 /dev/block/mmcblk1p2 /data/external
rm -rf /data/external/data
rm -rf /data/external/app

rm /data/scripts/vold.init/00_reset_card.sh
umount /data/external
rm -rf /data/external

echo "done removed self"
