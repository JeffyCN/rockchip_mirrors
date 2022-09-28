#! /bin/bash

if [ -f /usr/bin/firstboot.flag ]; then
	resize2fs /dev/mmcblk0p11
	rm -rf /usr/bin/firstboot.flag
fi
