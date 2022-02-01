#!/bin/sh
/etc/init.d/dockerd stop
parted /dev/mmcblk0 resizepart 2 100%

# inode needs to be resized for resize2fs to work correctly
# no idea why, actually /shrug
mount -o ro,remount /

#yolo
tune2fs -O^resize_inode /dev/mmcblk0p2
e2fsck -f -y /dev/mmcblk0p2
mount -o rw,remount /

resize2fs /dev/mmcblk0p2
