#!/bin/bash -e

OVERLAY_DIR="$1"
TARGET_DIR="$2"

rsync -av --chmod=u=rwX,go=rX "$OVERLAY_DIR/etc/" "$TARGET_DIR/"

if ! grep -wq "interfaces.d" "$TARGET_DIR/etc/network/interfaces"; then
	echo -e "\nsource-directory /etc/network/interfaces.d" >> \
		"$TARGET_DIR/etc/network/interfaces"
fi
