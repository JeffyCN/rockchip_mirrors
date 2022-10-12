#!/bin/sh

# Hooks for usbdevice

usb_pre_init_hook()
{
	echo 239 > bDeviceClass
	echo 2 > bDeviceSubClass
	echo 1 > bDeviceProtocol
}

usb_pre_stop_hook()
{
	killall rksl &>/dev/null || true
}

usb_post_stop_hook()
{
	usb_is_enabled || return 0

	# Sleep when restarting
	sleep 3
}
