#!/bin/bash -e

[ -x "$TARGET_DIR/usr/sbin/pm-suspend" ] || \
	[ -L "$TARGET_DIR/usr/sbin/pm-suspend" ]
