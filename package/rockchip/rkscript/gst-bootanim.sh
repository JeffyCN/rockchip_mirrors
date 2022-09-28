#!/bin/sh

VIDEO=$(ls /etc/bootanim.d/*.mp4 2>/dev/null)

[ -z "$VIDEO" ] && exit

VSINK_ARGS="kmssink force-modesetting=true"

# Uncomment for fullscreen
# VSINK_ARGS="$VSINK_ARGS fullscreen=true"

gst-play-1.0 $VIDEO -q --no-interactive --videosink="$VSINK_ARGS"
