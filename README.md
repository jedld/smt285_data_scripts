# smt285_data_scripts
Various shell scripts for hacking the Samsung Galaxy Tab A 7.0 SM-T285 using the PURE Tinker Edition custom ROM.

The Tinker Edition Custom ROM from THE SM-T285 allows for running shell scripts when those shell scripts are placed in
/data/scripts/vold.init/. This script technically runs as root, however due to selinux policies its access is severly limited. However it is good enough for having an "apps2sd" like hack, and with a device that comes with only 8GB ram and with 4GB of free space left this is a big deal.

mount_ext4_sdcard.sh - Script for moving apk and data files on boot to an ext4 formatted sd card like how apps2sd does it.
00_reset_card.sh - Script for disabling the apps2sd hack

Enabling the script
===========================

This procedure can cause loss of data, so make sure you have a backup, this script is still BETA I will not be responsible for any damage to your device.

Prerequisites
---------------

1. Galaxy Tab A (2016) 7.0" (SM-T285) running the PURE Tinker Edition ROM (Use ODIN/Heimdall to flash to your OEM unlocked device)
2. vfat and ext4 formatted micro SD Card with 2 partitions ( partition 1 -fat, partition 2 ext4). You can use gparted when using linux/ubuntu to achieve this. Not sure about windows but I believe there are tools to achieve the same effect. Best to use a fast sd card for a better user experience. Note that having a fat partition is necessary as some apps and services expect a fat filesystem for an external sd card. There may be a way to fix this but for now this is it. In theory using the apps2sd parition tool (https://play.google.com/store/apps/details?id=in.co.pricealert.apps2sd&hl=en) on another rooted phone with the sd card should work but haven't tried it personally.
3. Android tools namely adb (http://lifehacker.com/the-easiest-way-to-install-androids-adb-and-fastboot-to-1586992378)

Procedure
----------

It is recommended to do this on a clean device. 

1. Make sure developer options are enabled on your device (Tap Build Info 3 times) and enable USB debugging
2. Insert the formatted sdcard into the sdcard slot
3. Connect the USB cable to your galaxy tab A 2016
4. Clone this repo or just download the mount_ext4_sdcard.sh file. Go to where the mount_ext4_sdcard.sh script is and then

```
adb push mount_ext4_sdcard.sh /data/scripts/vold.init/
```

5. Then reboot your device. For this, you can manually restart it or just use the adb command:

```
adb reboot
```

After your device is done booting up, it should start moving your apps, if you think there are issues or you just want to make sure check the logs. 

```
adb pull /data/scripts/run-as-vold.log
```

You can also do "adb shell" and visit the specified location:

You should also notice sym links of your apps at /data/app and /data/data 

If you intend to customize the script you might want to also check /data/misc/audit/audit.log for sepolicy violations. Even as root you can't just exec/chmod/chown/etc. any file and expect to get away with it.

Note: The extra storage won't show up in settings when you query it, but your free space should increase. To know your free space, you have to go to the terminal or use adb shell and do

```
df
```

and check the size of /data/external


Important Notes
===============

- Apps are only moved during reboots. If you install a new app, simply reboot your device and it should
be moved to the ext4 partition automatically.
- Uninstalled apps are also only cleaned up after a reboot, unfortunately
- Not all apps are moved (system apps, samsung apps) are ignored. This is so that you have a somewhat working system if your sdcard is removed or fails for some reason. You can change this in the script (up to you)






