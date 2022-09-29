#!/bin/sh

# Uncomment below to see more logs
# set -x

MISC_DEV=$(realpath /dev/block/by-name/misc)

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

prepare_ubi()
{
	# Only support ubi for mtd device
	if echo $DEV | grep -vq /dev/mtd; then
		echo "$DEV is not a mtd device!"
		return 1
	fi

	[ "$PART_NO" ] || { echo "No valid part number!" && return 1; }

	if [ "$FSGROUP" == ubifs ]; then
		DEV=/dev/ubi${PART_NO}_0
	else
		DEV=/dev/ubiblock${PART_NO}_0
	fi

	MTDDEV=/dev/mtd${PART_NO}

	echo "Preparing $DEV from $MTDDEV"

	# Remove ubi block device
	if echo $DEV | grep -q ubiblock; then
		check_tool ubiblock BR2_PACKAGE_MTD_UBIBLOCK || return 1
		ubiblock -r /dev/ubi${PART_NO}_0 &>/dev/null
	fi

	# Detach ubi device
	check_tool ubidetach BR2_PACKAGE_MTD_UBIDETACH || return 1
	ubidetach -p $MTDDEV &>/dev/null

	# Attach ubi device
	check_tool ubiattach BR2_PACKAGE_MTD_UBIATTACH || return 1
	ubiattach /dev/ubi_ctrl -m $PART_NO -d $PART_NO || return 1

	# Check for valid volume
	if [ ! -e /dev/ubi${PART_NO}_0 ]; then
		echo "No valid ubi volume"
		return 1
	fi

	# Create ubi block device
	if echo $DEV | grep -q ubiblock; then
		check_tool ubiblock BR2_PACKAGE_MTD_UBIBLOCK || return 1
		ubiblock -c /dev/ubi${PART_NO}_0 || return 1
	fi

	return 0
}

format_ubifs()
{
	echo "Formatting $MTDDEV for $DEV"

	# Remove ubi block device
	if echo $DEV | grep -q ubiblock; then
		check_tool ubiblock BR2_PACKAGE_MTD_UBIBLOCK || return 1
		ubiblock -r /dev/ubi${PART_NO}_0 &>/dev/null
	fi

	# Detach ubi device
	check_tool ubidetach BR2_PACKAGE_MTD_UBIDETACH || return 1
	ubidetach -p $MTDDEV &>/dev/null

	# Format device
	check_tool ubiformat BR2_PACKAGE_MTD_UBIFORMAT || return 1
	ubiformat -yq $MTDDEV || return 1

	# Attach ubi device
	ubiattach /dev/ubi_ctrl -m $PART_NO -d $PART_NO || return 1

	# Create ubi volume
	check_tool ubimkvol BR2_PACKAGE_MTD_UBIMKVOL || return 1
	ubimkvol /dev/ubi$PART_NO -N $PART_NAME -m || return 1

	# Create ubi block device
	if echo $DEV | grep -q ubiblock; then
		check_tool ubiblock BR2_PACKAGE_MTD_UBIBLOCK || return 1
		ubiblock -c /dev/ubi${PART_NO}_0 || return 1
	fi
}

is_rootfs()
{
	[ $MOUNT_POINT = "/" ]
}

remount_part()
{
	mountpoint -q $MOUNT_POINT || return
	mount -o remount,${1:-rw} $MOUNT_POINT
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
		ubifs)
			format_ubifs
			;;
		squashfs)
			# check_tool mksquashfs BR2_PACKAGE_SQUASHFS && \
			# mksquashfs $DEV
			echo "It's pointness to format a squashfs partition..."
			;;
		auto)
			echo "Unable to format a auto partition..."
			;;
		*)
			echo Unsupported file system $FSTYPE for $DEV
			false
			;;
	esac
}

format_resize()
{
	BACKUP=$1
	SRC=$(realpath $MOUNT_POINT)

	echo "Format-resizing $DEV($FSTYPE)"

	# Backup original data
	cp -a "$SRC" "$BACKUP/" || return 1
	umount "$SRC" || return 1

	# Format and mount rw
	format_part || return 1
	mount_part || return 1
	remount_part rw

	# Restore backup data
	cp -a "$BACKUP/$SRC" $(dirname "$SRC") || return 1
}

resize_ext2()
{
	check_tool resize2fs BR2_PACKAGE_E2FSPROGS_RESIZE2FS || return 1

	resize2fs $DEV
}

resize_vfat()
{
	check_tool fatresize BR2_PACKAGE_FATRESIZE || return 1

	SIZE=$(fatresize -i $DEV | grep "Size:" | grep -o "[0-9]*$")

	# Somehow fatresize only works for 256M+ fat
	[ "$SIZE" -gt $((256 * 1024 * 1024)) ] && return 1

	MAX_SIZE=$(( $(cat $SYS_PATH/size) * 512))
	MIN_SIZE=$(($MAX_SIZE - 16 * 1024 * 1024))
	[ $MIN_SIZE -lt $SIZE ] && return 0 # Large enough!
	while [ $MAX_SIZE -gt $MIN_SIZE ];do
		# Somehow fatresize cannot resize to max size
		MAX_SIZE=$(($MAX_SIZE - 512 * 1024))

		# Try to resize with fatresize, not always work
		fatresize -s $MAX_SIZE $DEV && return
	done
	return 1
}

resize_ntfs()
{
	check_tool ntfsresize BR2_PACKAGE_NTFS_3G_NTFSPROGS || return 1

	echo y | ntfsresize -f $DEV
}

resize_part()
{
	# Unable to resize
	[ -z "$FSRESIZE" ] && return

	# Fixed size or already resized
	[ -f $MOUNT_POINT/.fixed -o -f $MOUNT_POINT/.resized ] && return

	echo "Resizing $DEV($FSTYPE)"

	# Online resize needs read-write
	remount_part rw
	if eval $FSRESIZE; then
		touch $MOUNT_POINT/.resized
		return
	fi

	# Done with rootfs
	is_rootfs && return

	# Fallback to format resize
	TEMP_BACKUP=$(mktemp -d)
	format_resize $TEMP_BACKUP && touch $MOUNT_POINT/.resized
	rm -rf $TEMP_BACKUP
}

erase_oem_command()
{
	CMD=$1
	FILE=$2

	echo "OEM: Erasing $CMD in $FILE"

	COUNT=$(echo $CMD | wc -c)
	OFFSETS=$(strings -t d $FILE | grep -w "$CMD" | awk '{ print $1 }')

	for offset in $OFFSETS; do
		dd if=/dev/zero of=$FILE bs=1 count=$COUNT seek=$offset conv=notrunc 2>/dev/null
	done
}

done_oem_command()
{
	CMD=$1

	echo "OEM: Done with $CMD"

	if [ -b "$MISC_DEV" ]; then
		erase_oem_command $CMD $MISC_DEV
	else
		echo "OEM: Erase $CMD from mtd device"

		check_tool nanddump BR2_PACKAGE_MTD_NANDDUMP || return
		check_tool nandwrite BR2_PACKAGE_MTD_NANDWRITE || return
		check_tool flash_erase BR2_PACKAGE_MTD_FLASH_ERASE || return

		TEMP=$(mktemp)
		nanddump $MISC_DEV -f $TEMP
		erase_oem_command $CMD $TEMP
		flash_erase $MISC_DEV 0 0
		nandwrite $MISC_DEV $TEMP
	fi
}

handle_oem_command()
{
	[ "$OEM_CMD" ] || return

	for cmd in $OEM_CMD; do
		case $cmd in
			cmd_wipe_$PART_NAME)
				is_rootfs && continue

				echo "OEM: $cmd - Wiping $DEV"
				format_part && done_oem_command $cmd
				;;
		esac
	done
}

convert_mount_opts()
{
	for opt in $@; do
		echo ${OPTS//,/ } | xargs -n 1 | grep -oE "^$opt$"
	done | tr "\n" ","
}

prepare_part()
{
	# Make sure other partitions are unmounted.
	is_rootfs || umount -l $MOUNT_POINT &>/dev/null

	case $FSTYPE in
		ext[234])
			FSGROUP=ext2
			FSCK_CONFIG=BR2_PACKAGE_E2FSPROGS_FSCK
			FSRESIZE=resize_ext2

			MOUNT="busybox mount"
			MOUNT_OPTS=$(convert_mount_opts "$BUSYBOX_MOUNT_OPTS")
			;;
		msdos|fat|vfat)
			FSGROUP=vfat
			FSCK_CONFIG=BR2_PACKAGE_DOSFSTOOLS_FSCK_FAT
			FSRESIZE=resize_vfat

			MOUNT="busybox mount"
			MOUNT_OPTS=$(convert_mount_opts "$BUSYBOX_MOUNT_OPTS")
			;;
		ntfs)
			FSGROUP=ntfs
			FSCK_CONFIG=BR2_PACKAGE_NTFS_3G_NTFSPROGS
			FSRESIZE=resize_ntfs

			MOUNT=ntfs-3g
			check_tool ntfs-3g BR2_PACKAGE_NTFS_3G || return 1
			MOUNT_OPTS=$(convert_mount_opts "$NTFS_3G_MOUNT_OPTS")
			;;
		ubi|ubifs)
			FSGROUP=ubifs
			# No fsck for ubifs
			unset FSCK_CONFIG
			# No resize for ubifs
			unset FSRESIZE

			MOUNT="busybox mount -t ubifs"
			MOUNT_OPTS=$(convert_mount_opts "$BUSYBOX_MOUNT_OPTS")
			;;
		squashfs)
			FSGROUP=squashfs
			# No fsck for squashfs
			unset FSCK_CONFIG
			# No resize for squashfs
			unset FSRESIZE

			MOUNT="busybox mount"
			MOUNT_OPTS=$(convert_mount_opts "$BUSYBOX_MOUNT_OPTS")
			;;
		auto)
			FSGROUP=auto
			# Running fsck on a random fs is dangerous
			unset FSCK_CONFIG
			# No resize for auto
			unset FSRESIZE

			MOUNT="busybox mount"
			MOUNT_OPTS=$(convert_mount_opts "$BUSYBOX_MOUNT_OPTS")
			;;
		*)
			echo "Unsupported file system $FSTYPE for $DEV"
			return
	esac

	# Will restore ro/rw at the end
	MOUNT_RO_RW=rw
	if echo $MOUNT_OPTS | grep -o "[^,]*ro\>" | grep "^ro$"; then
		MOUNT_RO_RW=ro
	fi

	MOUNT_OPTS=${MOUNT_OPTS:+" -o ${MOUNT_OPTS%,}"}

	# Prepare for ubi (consider /dev/mtdX as ubiblock)
	if [ $FSGROUP == ubifs ] || echo $DEV | grep -q "/dev/mtd[0-9]";then
		if ! prepare_ubi; then
			echo "Failed to prepare ubi for $DEV"
			[ "$AUTO_MKFS" ] || return 1

			echo "Auto formatting"
			format_ubifs || return 1
		fi
	fi
}

check_part()
{
	[ "$SKIP_FSCK" -o "$PASS" -eq 0 -o -z "$FSCK_CONFIG" ] && return
	echo "Checking $DEV($FSTYPE)"

	check_tool fsck.$FSGROUP $FSCK_CONFIG || return

	# Fsck needs read-only
	remount_part ro

	fsck.$FSGROUP -y $DEV
}

mount_part()
{
	echo "Mounting $DEV($FSTYPE) on $MOUNT_POINT ${MOUNT_OPTS:+with$MOUNT_OPTS}"
	$MOUNT $DEV $MOUNT_POINT $MOUNT_OPTS && return
	[ "$AUTO_MKFS" ] || return

	echo "Failed to mount $DEV, try to format it"
	format_part && \
		$MOUNT $DEV $MOUNT_POINT $MOUNT_OPTS
}

do_part()
{
	# Not enough args
	[ $# -lt 6 ] && return

	# Ignore comments
	echo $1 | grep -q "^#" && return

	DEV=$(echo $1 | sed "s#.*LABEL=#/dev/block/by-name/#")
	MOUNT_POINT=$2
	FSTYPE=$3
	OPTS=$4
	PASS=$6 # Skip fsck when pass is 0

	# Ignore external storages
	echo $MOUNT_POINT | grep -q "^\/mnt\/" && return

	# Find real dev for root dev
	if is_rootfs; then
		DEV=$(mountpoint -n / | cut -d ' ' -f 1)

		# Fallback to the by-name link
		[ "$DEV" ] || DEV=/dev/block/by-name/rootfs
	fi

	DEV=$(realpath $DEV 2>/dev/null)
	PART_NO=$(echo $DEV | grep -oE "[0-9]*$")

	# Unknown device
	[ -b "$DEV" -o -c "$DEV" ] || return

	SYS_PATH=$(echo /sys/class/*/${DEV##*/})
	if [ -f "$SYS_PATH/name" ]; then
		PART_NAME=$(cat $SYS_PATH/name)
	else
		PART_NAME=$(grep PARTNAME ${SYS_PATH}/uevent | cut -d '=' -f 2)
	fi
	PART_NAME=${PART_NAME:-${DEV##*/}}

	echo "Handling $PART_NAME: $DEV $MOUNT_POINT $FSTYPE $OPTS $PASS"

	# Setup check/mount tools and do some prepare
	prepare_part || return

	# Handle OEM commands for current partition
	handle_oem_command

	# Check and repair
	check_part

	# Mount partition
	is_rootfs || mount_part || return

	# Resize partition if needed
	resize_part

	# Restore ro/rw
	remount_part $MOUNT_RO_RW
}

prepare_mountall()
{
	OEM_CMD=$(strings "$MISC_DEV" | grep "^cmd_" | xargs)
	[ "$OEM_CMD" ] && echo "Note: Found OEM commands - $OEM_CMD"

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

		mountall 2>&1 | tee $LOGFILE
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
