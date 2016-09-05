#!/system/xbin/bash

####################################################
# auto-apps2sd by jedld for the SM-T285 v1.0
# requires an ext4 formatted SD card to work
####################################################

if [ ! -d "/data/external" ]; then
  mkdir /data/external
fi

chmod 777 /data/external
chmod 755 /data/app
chown system:system /data/external

mount -t ext4 /dev/block/mmcblk1p1 /data/external
chcon u:object_r:media_rw_data_file:s0 /data/external/lost+found

if [ ! -d "/data/external/app" ]; then
  busybox mkdir -Z u:object_r:apk_data_file:s0 /data/external/app
  chown system:system /data/external/app
fi

chcon u:object_r:apk_data_file:s0 /data/external/app
chmod 755 /data/external/app

if [ ! -d "/data/external/data" ]; then
    busybox mkdir -Z u:object_r:system_data_file:s0 /data/external/data
fi

chown system:system /data/external/data
chmod 755 /data/external/data

#Create standard external sdcard directories
sddirs=( "Download" "DCIM" "Movies" "Music" )

for dir in "${sddirs[@]}"
do
  if [ ! -d "/data/external/$dir" ]; then
    mkdir /data/external/$dir
    chown root:sdcard_r /data/external/$dir
    chmod 770 /data/external/$dir
    chcon u:object_r:media_rw_data_file:s0 /data/external/$dir
  fi
done

# copy non system files to /data/external/data
apps=($(ls /data/app/ -Z | grep :apk_data_file: | sed /com.google./d | sed /com.android./d | sed /com.sec./d | awk '{ print $5 }'))
for app in "${apps[@]}"
do
  if [ ! -e "/data/external/app/$app" ]; then
    echo "moving $app"
    /system/xbin/cp -a -c /data/app/$app /data/external/app/
    rm -rf /data/app/$app
    ln -sf /data/external/app/$app /data/app/$app
  fi
done

packages=($(ls /data/data/ -Z | grep :app_data_file: | sed /com.google./d | sed /com.sec.android./d | sed /com.android./d | sed /com.cyanogenmod./d | awk '{ print $5 }'))
#copy non system files to /data/external/data
for package in "${packages[@]}"
do
  if [ ! -e "/data/external/data/$package" ]; then
    echo "moving $package"
    /system/xbin/cp -a -c /data/data/$package /data/external/data/
    rm -rf /data/data/$package
    ln -sf /data/external/data/$package /data/data/$package
  fi
done
