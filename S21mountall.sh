#!/bin/sh

# Uncomment below to see more logs
# set -x

MISC_DEV=/dev/block/by-name/misc

BUSYBOX_MOUNT_OPTS="loop (a|)sync (no|)atime (no|)diratime (no|)relatime (no|)dev (no|)exec (no|)suid (r|)shared (r|)slave (r|)private (un|)bindable (r|)bind move remount ro"
NTFS_3G_MOUNT_OPTS="ro uid=[0-9]* gid=[0-9]* umask=[0-9]* fmask=[0-9]* dmask=[0-9]*"

check_tool()
{
	TOOL=$1
	CONFIG=$2

	type $TOOL >/dev/null && return 0

	[ -n "$CONFIG" ] && echo "You may need to enable $CONFIG"
	return 1
}

remount_part()
{
	mountpoint -q $MOUNT_POINT || return

	if touch $MOUNT_POINT &>/dev/null; then
		[ "$1" = ro ] && mount -o remount,ro $MOUNT_POINT
	else
		[ "$1" = rw ] && mount -o remount,rw $MOUNT_POINT
	fi
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

resize_ext2()
{
	check_tool resize2fs BR2_PACKAGE_E2FSPROGS_RESIZE2FS || return 1

	# Force using online resize, see:
	# https://bugs.launchpad.net/ubuntu/+source/e2fsprogs/+bug/1796788.
	TEMP=$(mktemp -d)
	$MOUNT $DEV $TEMP || return 1

	resize2fs $DEV && tune2fs $DEV -L $PART_NAME
	RET=$?

	umount $TEMP
	return $RET
}

resize_vfat()
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
		if fatresize -s ${MAX_SIZE} $DEV; then
			fatlabel $DEV $PART_NAME
			return 0
		fi
	done
	return 1
}

resize_ntfs()
{
	check_tool ntfsresize BR2_PACKAGE_NTFS_3G_NTFSPROGS || return 1
	echo y | ntfsresize -f $DEV && ntfslabel $DEV $PART_NAME
}

resize_part()
{
	# Already resized
	# Use volume label to mark resized
	[ "$FS_LABEL" = "$PART_NAME" ] && return

	echo "Resizing $DEV($FSTYPE)"

	# Resize needs read-write
	remount_part rw
	eval resize_$FSGROUP && return

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
	[ "$OEM_CMD" ] || return

	for cmd in $OEM_CMD; do
		case $cmd in
			cmd_wipe_$PART_NAME)
				[ "$IS_ROOTDEV" ] && continue

				echo "OEM: $cmd - Wiping $DEV"
				format_part && done_oem_command $cmd
				;;
		esac
	done
}

convert_mount_opts()
{
	for opt in $@; do
		echo $OPTS|grep -woE $opt
	done | tr "\n" ","
}

prepare_part()
{
	case $FSTYPE in
		ext[234])
			FSGROUP=ext2
			FSCK_CONFIG=BR2_PACKAGE_E2FSPROGS_FSCK
			;;
		msdos|fat|vfat)
			FSGROUP=vfat
			FSCK_CONFIG=BR2_PACKAGE_DOSFSTOOLS_FSCK_FAT
			;;
		ntfs)
			FSGROUP=ntfs
			FSCK_CONFIG=BR2_PACKAGE_NTFS_3G_NTFSPROGS
			;;
		*)
			echo "Unsupported file system $FSTYPE for $DEV"
			return 1
	esac

	case $FSGROUP in
		ext2)
			MOUNT="busybox mount"
			MOUNT_OPTS=$(convert_mount_opts "$BUSYBOX_MOUNT_OPTS")

			check_tool dumpe2fs BR2_PACKAGE_E2FSPROGS || return 1
			LABEL=$(dumpe2fs -h $DEV 2>/dev/null| grep "name:")
			;;
		vfat)
			MOUNT="busybox mount"
			MOUNT_OPTS=$(convert_mount_opts "$BUSYBOX_MOUNT_OPTS")

			check_tool fatlabel BR2_PACKAGE_DOSFSTOOLS_FATLABE || return 1
			LABEL=$(fatlabel $DEV)
			;;
		ntfs)
			MOUNT=ntfs-3g
			check_tool ntfs-3g BR2_PACKAGE_NTFS_3G || return 1
			MOUNT_OPTS=$(convert_mount_opts "$NTFS_3G_MOUNT_OPTS")

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

	FS_LABEL="$(echo $LABEL|xargs -n 1|tail -1)"

	MOUNT_OPTS=${MOUNT_OPTS:+" -o ${MOUNT_OPTS%,}"}

	# Try to umount the mounted partitions
	[ "$IS_ROOTDEV" ] || umount $MOUNT_POINT &>/dev/null
	mountpoint -q $MOUNT_POINT || return 0

	MOUNTED_RO_RW=$(touch $MOUNT_POINT &>/dev/null && echo rw || echo ro)
}

check_part()
{
	[ "$SKIP_FSCK" -o "$PASS" -eq 0 ] && return
	echo "Checking $DEV($FSTYPE)"

	check_tool fsck.$FSGROUP $FSCK_CONFIG || return

	# Fsck rootfs needs read-only
	[ "$IS_ROOTDEV" ] && remount_part ro

	fsck.$FSGROUP -y $DEV
}

do_part()
{
	# Not enough args
	[ $# -lt 6 ] && return

	# Ignore comments
	echo $1 |grep -q "^#" && return

	DEV=$1
	MOUNT_POINT=$2
	FSTYPE=$3
	OPTS=$4
	PASS=$6 # Skip fsck when pass is 0

	IS_ROOTDEV=$(echo $MOUNT_POINT | grep -w '/')

	# Find real dev for root dev
	if [ "$IS_ROOTDEV" ];then
		DEV=$(mountpoint -n /|cut -d ' ' -f 1)

		# Fallback to the by-name link
		[ "$DEV" ] || DEV=/dev/block/by-name/rootfs
	fi

	DEV=$(realpath $DEV 2>/dev/null)

	# Unknown device
	[ -b "$DEV" ] || return

	echo "Handling $DEV $MOUNT_POINT $FSTYPE $OPTS $PASS"

	SYS_PATH=/sys/class/block/${DEV##*/}
	MAX_SIZE=$(( $(cat ${SYS_PATH}/size) * 512))
	PART_NAME=$(grep PARTNAME ${SYS_PATH}/uevent | cut -d '=' -f 2)

	# Handle OEM commands for current partition
	handle_oem_command

	# Check fs types and setup check/mount tools
	prepare_part || return

	# Resize partition if needed
	resize_part

	# Check and repair
	check_part

	# Restore ro/rw
	remount_part $MOUNTED_RO_RW

	# Done with rootdev
	[ "$IS_ROOTDEV" ] && return

	# Done with mounted partitions
	if mountpoint -q $MOUNT_POINT; then
		echo "Already mounted $DEV($MOUNT_POINT)"
		return
	fi

	echo "Mounting $DEV($FSTYPE) on $MOUNT_POINT ${MOUNT_OPTS:+with$MOUNT_OPTS}"
	$MOUNT $DEV $MOUNT_POINT $MOUNT_OPTS && return
	[ "$AUTO_MKFS" ] || return

	echo "Failed to mount $DEV, try to format it"
	format_part && \
		$MOUNT $DEV $MOUNT_POINT $MOUNT_OPTS
}

prepare_mountall()
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

	# Set environments for mountall
	prepare_mountall

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
