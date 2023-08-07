#!/bin/bash -e

OVERLAY_DIR="$1"
TARGET_DIR="$2"

rsync -av --chmod=u=rwX,go=rX "$OVERLAY_DIR/common/" "$TARGET_DIR/"

if [ -x "$TARGET_DIR/usr/bin/chromium" -o \
	-L "$TARGET_DIR/usr/bin/chromium" ]; then
	rsync -av --chmod=u=rwX,go=rX "$OVERLAY_DIR/chromium/" "$TARGET_DIR/"
fi
