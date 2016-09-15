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
echo "copying files to external backup location"
busybox mkdir -Z u:object_r:media_rw_data_file:s0 /data/external/tmp
tmpdir=/data/external/tmp/backup_$now
busybox mkdir -Z u:object_r:media_rw_data_file:s0 $tmpdir

/system/xbin/cp -a /data/app-asec $tmpdir/
/system/xbin/cp -a /data/app-lib $tmpdir/
/system/xbin/cp -a /data/data $tmpdir/
/system/xbin/cp -a /data/app $tmpdir/
/system/xbin/cp -a /data/media $tmpdir/
/system/xbin/cp -a /data/mediadrm $tmpdir/
/system/xbin/cp -a /data/security $tmpdir/
/system/xbin/cp -a /data/scripts $tmpdir/
/system/xbin/cp -a /data/user $tmpdir/
/system/xbin/cp -a /data/system $tmpdir/
/system/xbin/cp -a /data/drm $tmpdir/
/system/xbin/cp -a /data/property $tmpdir/
/system/xbin/cp -a /data/local $tmpdir/
echo "copying files done."

# generate file_contexts
echo "# file contexts for /data" > $tmpdir/file_contexts

echo "generating context file"
files=($(busybox ls -d -1 /data/*))

echo "# directories" >> $tmpdir/file_contexts
for file in "${files[@]}"
do
  if [ -d "$file" ]; then
    busybox ls -Z -d -1 $file | awk '{print $3 "(/.*)?        " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $tmpdir/file_contexts
  fi
done

files=($(busybox ls -1 /data/*))

echo "# app data" >> $tmpdir/file_contexts
for file in "${files[@]}"
do
  if [ -f "$file" ]; then
    busybox ls -Z -d -1 $file | awk '{print $3 "            " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $tmpdir/file_contexts
  fi
done

files=($(busybox ls -d -1 /data/data/*))

echo "# app data" >> $tmpdir/file_contexts
for file in "${files[@]}"
do
  if [ -d "$file" ]; then
    busybox ls -Z -d -1 $file | awk '{print $3 "(/.*)?        " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $tmpdir/file_contexts
  else
    busybox ls -Z -d -1 $file | awk '{print $3 "       " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $tmpdir/file_contexts
  fi
done

files=($(busybox ls -d -1 /data/app/*))
echo "# app binary" >> $tmpdir/file_contexts
for file in "${files[@]}"
do
  if [ -d "$file" ]; then
    busybox ls -Z -d -1 $file | awk '{print $3 "(/.*)?        " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $tmpdir/file_contexts
  else
    busybox ls -Z -d -1 $file | awk '{print $3 "               " $2 }' | sed /No\ such\ file\ or\ directory/d  >> $tmpdir/file_contexts
  fi
done

echo "# files" >> $tmpdir/file_contexts
busybox ls -Z -d -1  /data/**/* | awk '{print $3 "        " $2}' | sed /No\ such\ file\ or\ directory/d  >> $tmpdir/file_contexts
echo "generating context file done."


filename=/data/external/misc/backup_$now.tar.gz
echo "compressing backup file to $filename"
cd $tmpdir
tar -czvf $filename .
chmod 777 $filename
echo "compress done. cleaning up..."
rm -rf $tmpdir


rm /data/scripts/vold.init/00_backup_apps.sh
