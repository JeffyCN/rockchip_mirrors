#!/bin/bash -e

OVERLAYS="$(dirname "$0")/overlays"
for dir in $(ls "$OVERLAYS"); do
	OVERLAY_DIR="$OVERLAYS/$dir"
	if [ -x "$OVERLAY_DIR/check.sh" ] && ! "$OVERLAY_DIR/check.sh"; then
		echo "Ignored $OVERLAY_DIR"
		continue
	fi

	if [ -x "$OVERLAY_DIR/install.sh" ]; then
		echo "Installing $OVERLAY_DIR"
		"$OVERLAY_DIR/install.sh"
	else
		echo "Copying $OVERLAY_DIR"
                rsync -av --chmod=u=rwX,go=rX \
			--exclude .empty --exclude /check.sh \
			"$OVERLAY_DIR/" "$TARGET_DIR/"
	fi
done

POST_SCRIPT="../device/rockchip/common/post-build.sh"
if [ -x "$POST_SCRIPT" ]; then
	export $(grep "^BR2_DEFCONFIG=" "$BR2_CONFIG")
	$POST_SCRIPT "$TARGET_DIR" "$(basename $BR2_DEFCONFIG)"
fi

exit 0
