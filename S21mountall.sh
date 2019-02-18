#!/bin/sh

# Uncomment below to see more logs
# set -x

MISC_DEV=/dev/block/by-name/misc

check_tool()
{
	TOOL=$1
	CONFIG=$2

	type $TOOL >/dev/null && return 0

	[ -n "$CONFIG" ] && echo "You may need to enable $CONFIG"
	return 1
}

format_part()
{
	echo "Formatting $DEV($FSTYPE)"

	case $FSGROUP in
		ext2)
			# Set max-mount-counts to 0, and disable the time-dependent checking.
			check_tool mke2fs BR2_PACKAGE_E2FSPROGS && \
			mke2fs -F -L $PART_NAME $DEV && \
			tune2fs -c 0 -i 0 $DEV
			;;
		vfat)
			# Use fat32 by default
			check_tool mkfs.vfat BR2_PACKAGE_DOSFSTOOLS_MKFS_FAT && \
			mkfs.vfat -I -F 32 -n $PART_NAME $DEV
			;;
		ntfs)
			# Enable compression
			check_tool mkntfs BR2_PACKAGE_NTFS_3G_NTFSPROGS && \
			mkntfs -FCQ -L $PART_NAME $DEV
			;;
		*)
			echo Unsupported file system $FSTYPE for $DEV
			false
			;;
	esac
}

need_resize()
{
	case $FSGROUP in
		ext2)
			check_tool dumpe2fs BR2_PACKAGE_E2FSPROGS || return 1
			LABEL=$(dumpe2fs -h $DEV | grep "name:")
			;;
		vfat)
			check_tool fatlabel BR2_PACKAGE_DOSFSTOOLS_FATLABE || return 1
			LABEL=$(fatlabel $DEV)
			;;
		ntfs)
			check_tool ntfslabel BR2_PACKAGE_NTFS_3G_NTFSPROGS || return 1
			LABEL=$(ntfslabel $DEV)
			;;
		*)
			echo Unsupported file system $FSTYPE for $DEV
			return 1
			;;
	esac

	if [ $? -ne 0 ]; then
		echo "Wrong fs type($FSTYPE) for $DEV"
		return 1
	fi

	# Use volume label to mark resized
	[ "$(echo $LABEL|xargs -n 1|tail -1)" != "$PART_NAME" ]
}

format_resize()
{
	TEMP=$(mktemp -d)
	$MOUNT $DEV $TEMP || return 1

	USED_SIZE=$(df $TEMP|tail -1|awk '{ print $3 }')
	TEMP_SIZE=$(df /tmp/|tail -1|awk '{ print $4 }')
	if [ $USED_SIZE -gt $(($TEMP_SIZE - 4096)) ]; then
		umount $TEMP
		return 1
	fi

	echo "Format-resizing $DEV($FSTYPE)"

	TARBALL=/tmp/${PART_NAME}.tar

	# Backup original data
	tar cf $TARBALL $TEMP
	umount $TEMP

	format_part || { rm $TARBALL; return 1; }

	# Restore backup data
	$MOUNT $DEV $TEMP
	tar xf $TARBALL -C /
	rm $TARBALL

	umount $TEMP
}

resize_fatresize()
{
	check_tool fatresize BR2_PACKAGE_FATRESIZE || return 1

	SIZE=$(fatresize -i $DEV | grep "Size:" | grep -o "[0-9]*$")

	# Somehow fatresize only works for 256M+ fat
	[ $SIZE -gt $((256 * 1024 * 1024)) ] && return 1

	MIN_SIZE=$(($MAX_SIZE - 16 * 1024 * 1024))
	[ $MIN_SIZE -lt $SIZE ] && return 0 # Large enough!
	while [ $MAX_SIZE -gt $MIN_SIZE ];do
		# Somehow fatresize cannot resize to max size
		MAX_SIZE=$(($MAX_SIZE - 512 * 1024))

		# Try to resize with fatresize, not always work
		fatresize -s ${MAX_SIZE} $DEV && return
	done

	return 1
}

resize_ext2()
{
	check_tool resize2fs BR2_PACKAGE_E2FSPROGS_RESIZE2FS || return

	# Force using online resize, see:
	# https://bugs.launchpad.net/ubuntu/+source/e2fsprogs/+bug/1796788.
	TEMP=$(mktemp -d)
	$MOUNT $DEV $TEMP || return
	resize2fs $DEV && tune2fs $DEV -L $PART_NAME
	umount $TEMP
}

resize_vfat()
{
	check_tool fatlabel BR2_PACKAGE_DOSFSTOOLS_FATLABE || return
	resize_fatresize && fatlabel $DEV $PART_NAME
}

resize_ntfs()
{
	check_tool ntfsresize BR2_PACKAGE_NTFS_3G_NTFSPROGS || return
	echo y | ntfsresize -f $DEV && ntfslabel $DEV $PART_NAME
}

resize_part()
{
	need_resize || return

	echo "Resizing $DEV($FSTYPE)"

	case $FSGROUP in
		ext2|vfat|ntfs)
			eval resize_$FSGROUP
			;;
		*)
			echo Unsupported file system $FSTYPE for $DEV
			return
			;;
	esac

	need_resize || return

	# Fallback to format resize
	[ ! "$IS_ROOTDEV" ] && format_resize
}

done_oem_command()
{
	echo "OEM: Done with $cmd"
	COUNT=$(echo $cmd|wc -c)
	OFFSETS=$(strings -t d $MISC_DEV | grep -w "$cmd" | awk '{ print $1 }')

	for offset in $OFFSETS; do
		dd if=/dev/zero of=$MISC_DEV bs=1 count=$COUNT seek=$offset 2>/dev/null
	done
}

handle_oem_command()
{
	[ "$IS_ROOTDEV" ] && return
	[ "$OEM_CMD" ] || return

	for cmd in $OEM_CMD; do
		case $cmd in
			cmd_wipe_$PART_NAME)
				echo "OEM: $cmd - Wiping $DEV"
				format_part && done_oem_command $cmd
				;;
		esac
	done
}

do_part()
{
	# Not enough args
	[ $# -lt 3 ] && return

	# Ignore comments
	echo $1 |grep -q "^#" && return

	DEV=$1
	MOUNT_POINT=$2
	FSTYPE=$3
	IS_ROOTDEV=$(echo $MOUNT_POINT | grep -w '/')

	# Find real dev for root dev
	if [ "$IS_ROOTDEV" ];then
		DEV=$(mountpoint -n /|cut -d ' ' -f 1)
	fi

	DEV=$(realpath $DEV 2>/dev/null)

	# Unknown device
	[ -b "$DEV" ] || return

	SYS_PATH=/sys/class/block/${DEV##*/}
	MAX_SIZE=$(( $(cat ${SYS_PATH}/size) * 512))
	PART_NAME=$(grep PARTNAME ${SYS_PATH}/uevent | cut -d '=' -f 2)

	echo "Handling $DEV $MOUNT_POINT $FSTYPE"

	# Skip mounted partitions
	if [ ! "$IS_ROOTDEV" ] && mountpoint -q $MOUNT_POINT; then
		echo "Already mounted $DEV($MOUNT_POINT)"
		return
	fi

	MOUNT="mount -t $FSTYPE"
	case $FSTYPE in
		ext[234])
			FSGROUP=ext2
			check_tool fsck.$FSGROUP BR2_PACKAGE_E2FSPROGS_FSCK || return
			;;
		msdos|fat|vfat)
			FSGROUP=vfat
			check_tool fsck.$FSGROUP BR2_PACKAGE_DOSFSTOOLS_FSCK_FAT || return
			;;
		ntfs)
			FSGROUP=ntfs
			MOUNT=ntfs-3g
			check_tool fsck.$FSGROUP BR2_PACKAGE_NTFS_3G_NTFSPROGS || return
			;;
		*)
			echo "Unsupported file system $FSTYPE for $DEV"
			return
	esac

	# Handle OEM commands for current partition
	handle_oem_command

	resize_part

	# Done with rootdev
	[ "$IS_ROOTDEV" ] && return

	if [ ! "$SKIP_FSCK" ]; then
		echo "Checking $DEV($FSTYPE)"
		fsck.$FSGROUP -y $DEV
	fi

	echo "Mounting $DEV($FSTYPE)"
	$MOUNT $DEV $MOUNT_POINT && return
	[ "$AUTO_MKFS" ] || return

	echo "Failed to mount $DEV, try to format it"
	format_part && $MOUNT $DEV $MOUNT_POINT
}

prepare_mount()
{
	OEM_CMD=$(strings $MISC_DEV | grep "^cmd_" | xargs)
	[ "$OEM_CMD" ] && echo "Note: Fount OEM commands - $OEM_CMD"

	AUTO_MKFS="/.auto_mkfs"
	if [ -f $AUTO_MKFS ];then
		echo "Note: Will auto format partitons, remove $AUTO_MKFS to disable"
	else
		unset AUTO_MKFS
	fi

	SKIP_FSCK="/.skip_fsck"
	if [ -f $SKIP_FSCK ];then
		echo "Note: Will skip fsck, remove $SKIP_FSCK to enable"
	else
		echo "Note: Create $SKIP_FSCK to skip fsck"
		echo " - The check might take a while if didn't shutdown properly!"
		unset SKIP_FSCK
	fi
}

mountall()
{
	# Recovery's rootfs is ramfs
	if mountpoint -d /|grep -wq 0:1; then
		echo "Only mount basic file systems for recovery"
		return
	fi

	echo "Will now mount all partitions in /etc/fstab"

	prepare_mount
	while read LINE;do
		do_part $LINE
	done < /etc/fstab
}

case "$1" in
	start|"")
		# Mount basic file systems firstly
		mount -a -t "proc,devpts,tmpfs,sysfs,debugfs,pstore"

		LOGFILE=/tmp/mountall.log

		mountall 2>&1 |tee $LOGFILE
		echo "Log saved to $LOGFILE"
		;;
	restart|reload|force-reload)
		echo "Error: argument '$1' not supported" >&2
		exit 3
		;;
	stop|status)
		# No-op
		;;
	*)
		echo "Usage: [start|stop]" >&2
		exit 3
		;;
esac

:
