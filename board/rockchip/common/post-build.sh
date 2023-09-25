#!/bin/bash -e

TARGET_DIR="${TARGET_DIR:-"$@"}"

OVERLAYS="$(dirname "$0")/overlays"
for dir in $(ls "$OVERLAYS"); do
	OVERLAY_DIR="$OVERLAYS/$dir"
	if [ -x "$OVERLAY_DIR/prepare.sh" ] && \
		! "$OVERLAY_DIR/prepare.sh" "$TARGET_DIR"; then
		echo "Ignored $OVERLAY_DIR"
		continue
	fi

	echo "Copying $OVERLAY_DIR"
	rsync -av --chmod=u=rwX,go=rX --exclude .empty --exclude /prepare.sh \
		"$OVERLAY_DIR/" "$TARGET_DIR/"
done

POST_SCRIPT="../device/rockchip/common/post-build.sh"
if [ -x "$POST_SCRIPT" ]; then
	export $(grep "^BR2_DEFCONFIG=" "${BR2_CONFIG:-"$TARGET_DIR/../.config"}")
	$POST_SCRIPT "$(realpath "$TARGET_DIR")" "$(basename "$BR2_DEFCONFIG")"
fi

exit 0
