#!/bin/bash -e

[ -x "$TARGET_DIR/usr/bin/weston" ]
[ -x "$TARGET_DIR/usr/bin/chromium" ] || [ -L "$TARGET_DIR/usr/bin/chromium" ]
