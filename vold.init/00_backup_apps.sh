#!/system/xbin/bash

####################################################
# auto-apps2sd by jedld for the SM-T285 v1.0
# requires an ext4 formatted SD card to work
#
# WARNING THIS SCRIPT CAN CAUSE DATA LOSS
# THIS IS PROVIDED AS-IS WITH NO WARRANTIES
####################################################

# change this to point to the ext4 partition on your sdcard
# e.g. mmcblk1p1 for partition 1 or mmcblk1p2 for partition 2
ext4part=mmcblk1p2

echo "====================================="
echo "  backup version 1.0 by jedld  "
echo "====================================="
if [ ! -d "/data/external" ]; then
  mkdir /data/external
fi

chmod 755 /data/app
chown system:system /data/external

# mount partition 2 of the sdcard, change this to customize your partiton scheme
echo "mounting $ext4part to /data/external"
mount -t ext4 /dev/block/$ext4part /data/external
chmod 777 /data/external
chcon u:object_r:media_rw_data_file:s0 /data/external
chcon u:object_r:media_rw_data_file:s0 /data/external/lost+found

busybox mkdir -Z u:object_r:media_rw_data_file:s0 /data/external/backups
chown root:sdcard_r /data/external/backups
chmod 777 /data/external/backups

now=$(date +"%m_%d_%Y_%H%M%s")

file_context_name=/data/external/misc/file_contexts_$now

# generate file_contexts
echo "# file contexts for /data" > $file_context_name


echo "generating context file"

busybox ls -Z -d -1 -a /data | awk '{print $3 "(/.*)?        " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $file_context_name

files=($(busybox ls -d -a -1 /data/*))
echo "# directories" >> $file_context_name
for file in "${files[@]}"
do
  if [ -d "$file" ]; then
    busybox ls -Z -d -1 -a $file | awk '{print $3 "(/.*)?        " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $file_context_name
  else
    busybox ls -Z -d -1 -a $file | awk '{print $3 "              " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $file_context_name
  fi
done

backup_dirs=("app" "data" "system" "security" "app-lib" "app-asec" "property")

for dir in "${backup_dirs[@]}"
do
  echo "# $dir" >> $file_context_name
  echo "# " >> $file_context_name
  files=($(busybox ls -1 -d -a /data/$dir/*))
  for file in "${files[@]}"
  do
    if [ -d "$file" ]; then
      busybox ls -Z -d -a -1 $file | awk '{print $3 "(/.*)?            " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $file_context_name
    else
      busybox ls -Z -d -a -1 $file | awk '{print $3 "                  " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $file_context_name
    fi
  done
done

backup_dirs=("media" "mediadrm" "scripts" "user" "drm" "local" "misc")

for dir in "${backup_dirs[@]}"
do
  echo "# $dir" >> $file_context_name
  echo "# " >> $file_context_name
  files=($(busybox ls -1 -d -a /data/$dir/**/*))
  for file in "${files[@]}"
  do

    if [ -d "$file" ]; then
      busybox ls -Z -d -a -1 $file | awk '{print $3 "(/.*)?            " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $file_context_name
    else
      busybox ls -Z -d -a -1 $file | awk '{print $3 "                  " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $file_context_name
    fi
  done
done
echo "generating context file done."

filename=/data/external/misc/backup_$now.tar.gz
echo "compressing backup file to $filename"

cd /data
tar -czvp --exclude backups -T /data/external/misc/file_contexts_$now --exclude scripts/vold.init/00_backup_apps.sh --exclude external -f $filename .

chmod 777 $filename
chmod 777 /data/external/misc/file_contexts_$now
echo "compress done. cleaning up..."

rm /data/scripts/vold.init/00_backup_apps.sh
