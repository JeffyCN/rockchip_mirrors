#!/bin/bash -e

[ -x "$TARGET_DIR/usr/sbin/wpa_supplicant" ]
[ -x "$TARGET_DIR/sbin/dhcpcd" ]
[ -r "$TARGET_DIR/etc/network/interfaces" ]
[ -r "$TARGET_DIR/etc/wpa_supplicant.conf" ]

if ! grep -wq "interfaces.d" "$TARGET_DIR/etc/network/interfaces"; then
	echo -e "\nsource-directory /etc/network/interfaces.d" >> \
		"$TARGET_DIR/etc/network/interfaces"
fi
