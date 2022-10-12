#!/bin/sh

# Override for UVC

UVC_INSTANCES="uvc.gs1 uvc.gs2"

uvc_add_yuyv()
{
	WIDTH=$(echo $1 | cut -d'x' -f1)
	HEIGHT=$(echo $1 | cut -d'x' -f2)
	DIR=${HEIGHT}p

	[ ! -d $DIR ] || return 0

        mkdir -p $DIR
        echo $WIDTH > $DIR/wWidth
        echo $HEIGHT > $DIR/wHeight
        echo 666666 > $DIR/dwDefaultFrameInterval
        echo $((WIDTH * HEIGHT * 80)) > $DIR/dwMinBitRate
        echo $((WIDTH * HEIGHT * 160)) > $DIR/dwMaxBitRate
        echo $((WIDTH * HEIGHT * 2)) > $DIR/dwMaxVideoFrameBufferSize
        echo -e "666666\n1000000\n2000000" > $DIR/dwFrameInterval
}

uvc_add_mjpeg()
{
	WIDTH=$(echo $1 | cut -d'x' -f1)
	HEIGHT=$(echo $1 | cut -d'x' -f2)
	DIR=${HEIGHT}p

	if [ "${WIDTH}x${HEIGHT}" = 1280x1080 ]; then
		DIR=1280p
	fi

	[ ! -d $DIR ] || return 0

        mkdir -p $DIR
        echo $WIDTH > $DIR/wWidth
        echo $HEIGHT > $DIR/wHeight
        echo 333333 > $DIR/dwDefaultFrameInterval
        echo $((WIDTH * HEIGHT * 80)) > $DIR/dwMinBitRate
        echo $((WIDTH * HEIGHT * 160)) > $DIR/dwMaxBitRate
        echo $((WIDTH * HEIGHT * 2)) > $DIR/dwMaxVideoFrameBufferSize
        echo -e "333333\n500000\n666666\n1000000" > $DIR/dwFrameInterval
}

uvc_add_h264()
{
	WIDTH=$(echo $1 | cut -d'x' -f1)
	HEIGHT=$(echo $1 | cut -d'x' -f2)
	DIR=${HEIGHT}p

	[ ! -d $DIR ] || return 0

        mkdir -p $DIR
        echo $WIDTH > $DIR/wWidth
        echo $HEIGHT > $DIR/wHeight
        echo 333333 > $DIR/dwDefaultFrameInterval
        echo $((WIDTH * HEIGHT * 10)) > $DIR/dwMinBitRate
        echo $((WIDTH * HEIGHT * 10)) > $DIR/dwMaxBitRate
        echo -e "333333\n400000\n500000\n666666\n1000000" > $DIR/dwFrameInterval
}

uvc_support_resolutions()
{
	case ${1:-yuyv} in
		yuyv)	echo "640x360 640x480 1280x720";;
		mjpeg)	echo "640x360 640x480 1280x720 1920x1080";;
		h264)	echo "1280x720 1920x1080";;
	esac
}

uvc_pre_prepare_hook()
{
	UVC_DIR=$(pwd)
	UVC_NAME=UVC

	case "$(basename $UVC_DIR)" in
		uvc.gs1)	UVC_NAME="UVC RGB";;
		uvc.gs2)	UVC_NAME="UVC IR";;
	esac
	usb_try_write device_name "UVC_NAME"

	#echo 3072 > streaming_maxpacket
	usb_try_write uvc_num_request 2
	usb_try_write streaming_bulk 1
}
