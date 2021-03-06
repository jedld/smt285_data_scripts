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
echo "  auto-apps2sd version 1.0 by jedld  "
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

if [ ! -d "/data/external/app" ]; then
  busybox mkdir -Z u:object_r:apk_data_file:s0 /data/external/app
  chown system:system /data/external/app
fi

chmod 755 /data/external/app

if [ ! -d "/data/external/data" ]; then
    busybox mkdir -Z u:object_r:system_data_file:s0 /data/external/data
fi

chown system:system /data/external/data
chmod 755 /data/external/data

#Create standard external sdcard directories
sddirs=( "misc" )

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
apps=($(ls /data/app/ -Z | grep :apk_data_file: | sed /com.google./d | sed /.xposed/d | sed /com.android./d | sed /com.sec./d | awk '{ print $5 }'))
for app in "${apps[@]}"
do
  if [ ! -e "/data/external/app/$app" ]; then
    echo "moving apk $app"
    /system/xbin/cp -a /data/app/$app /data/external/app/
    if [ $? -eq 0 ];
    then
      rm -rf /data/app/$app
      ln -sf /data/external/app/$app /data/app/$app
    fi
  fi
done

packages=($(ls /data/data/ -Z | grep :app_data_file: | sed /com.google./d | sed /.xposed/d | sed /com.sec.android./d | sed /com.android./d | sed /com.cyanogenmod./d | awk '{ print $5 }'))
#copy non system files to /data/external/data
for package in "${packages[@]}"
do
  if [ ! -e "/data/external/data/$package" ]; then
    echo "moving data $package"
    /system/xbin/cp -a -c /data/data/$package /data/external/data/
    if [ $? -eq 0 ];
    then
      rm -rf /data/data/$package
      ln -sf /data/external/data/$package /data/data/$package
    fi
  fi
done

echo "move data done."


echo "making sure package manager is up"
sleep 20
# cleanup uninstalled apps
pm list packages
if [ $? -eq 0 ];
then
  echo "cleaning up uninstalled apps"
  installed=($(pm list packages -f | sed -e 's/.*=//'))

  uapks=($(ls /data/external/app/ -Z | awk '{ print $5 }'))

  for uapk in "${uapks[@]}"
  do
    if [[ " ${installed[@]} " =~ " ${uapk::-2} " ]]; then
      # ok file exists
      echo "."
    else
      echo "cleaning up ${uapk::-2} apk: $uapk"
      rm -rf /data/external/app/$uapk
      # cleanup link
      rm /data/app/$uapk
    fi
  done

  udatas=($(ls /data/external/data/ -Z | awk '{ print $5 }'))

  for udata in "${udatas[@]}"
  do
    if [[ " ${installed[@]} " =~ " ${udata} " ]]; then
      # ok file exists
      echo "."
    else
      echo "cleaning up data: $udata"
      rm -rf /data/external/data/$udata
      rm /data/data/$udata
    fi
  done
  echo "cleanup apps done"
fi
