SHELL = /bin/bash
.PHONY: all clean help install
include $(shell pwd)/../../device/rockchip/.BoardConfig.mk
include $(shell pwd)/../../distro/output/.config
install:
	install -m 0755 -D S50usbdevice /etc/init.d/
	install -m 0644 -D 61-usbdevice.rules /lib/udev/rules.d/
	install -m 0755 -D usbdevice /usr/bin/
	install -m 0755 -D glmarktest.sh /usr/bin/
	install -m 0755 -D gstaudiotest.sh /usr/bin/
	install -m 0755 -D gstmp3play.sh /usr/bin/
	install -m 0755 -D gstmp4play.sh /usr/bin/
	install -m 0755 -D gstvideoplay.sh /usr/bin/
	install -m 0755 -D gstvideotest.sh /usr/bin/
	install -m 0755 -D gstwavplay.sh /usr/bin/
	install -m 0755 -D mp3play.sh /usr/bin/
	install -m 0755 -D waylandtest.sh /usr/bin/
	install -m 0755 -D S21mountall.sh /etc/init.d/
	install -m 0755 -D fstab /etc/
	install -m 0644 -D 61-partition-init.rules /lib/udev/rules.d/
	install -m 0644 -D 61-sd-cards-auto-mount.rules /lib/udev/rules.d/
	install -m 0755 -D resize-helper /usr/sbin/
	install -m 0755 -D S22resize-disk /etc/init.d/
	`echo -e "/dev/disk/by-partlabel/oem\t/oem\t\t\t$(RK_OEM_FS_TYPE)\t\tdefaults\t\t0\t2" > /etc/fstab` && \
	`echo -e "/dev/disk/by-partlabel/userdata\t/userdata\t\t$(RK_USERDATA_FS_TYPE)\t\tdefaults\t\t0\t2" >> /etc/fstab`
	install -m 0644 -D asound.conf.in /etc/asound.conf && sed -i "s#\#PCM_ID#${BR2_PACKAGE_RKSCRIPT_DEFAULT_PCM}#g" /etc/asound.conf
	mkdir -p /oem /userdata /mnt/sdcard
	cd / && ln -fs userdata data && ln -fs mnt/sdcard sdcard && cd -
	[ ! -e  /etc/init.d/.usb_config ] && touch /etc/init.d/.usb_config || true
	[ ! `grep usb_ums_en /etc/init.d/.usb_config` ] && `echo usb_ums_en >> /etc/init.d/.usb_config` || true
	[ ! `grep usb_adb_en /etc/init.d/.usb_config` ] && `echo usb_adb_en >> /etc/init.d/.usb_config` || true

