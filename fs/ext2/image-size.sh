#!/bin/sh -e
#
# Usage: image-size.sh <dir> <type(ext2|ext3|ext4)> <blksz>

TARGET_DIR="$1"
FS_TYPE="${2:-ext4}"
BLKSZ="${3:-4096}"

FILE_SIZE="$(du --apparent-size -shm $TARGET_DIR | cut -f1)"
MAX_ALIGNMENT_SIZE="$(( $(find $TARGET_DIR | wc -l) * $BLKSZ / 1024 / 1024 ))"
ROOTFS_SIZE="$(( ($FILE_SIZE + $MAX_ALIGNMENT_SIZE) * 1.1 + 64))"

if [ "$ROOTFS_SIZE" -lt 122 ]; then
	JNL_SIZE="$(( $BLKSZ / 1024 ))"
elif [ "$ROOTFS_SIZE" -lt 976 ]; then
	JNL_SIZE=16
elif [ "$ROOTFS_SIZE" -lt 1951 ]; then
	JNL_SIZE=64
elif [ "$ROOTFS_SIZE" -lt 15604 ]; then
	JNL_SIZE=128
fi

1024
1-30 1      30
31-243 4    244
244-487 8    488

2048
4-60 2      30
61-487 8    244
488-976 16  488
    8192 32 3901     64 * 64          4096         16

4096
8-121 4     2 30          4 * 8         32           1
122-975 16  244        16 * 16          256          4
976-1951 32 488       16 * 32           512          8
1952-15603 64 3901     64 * 64          4096         16
15604-31207 128 7802     64 * 128       8192         32
31208-62415 256  15604     128 * 128    16384        64
62415*2 512  15604*2   128 * 256    32768        128
31208-62415 1024  15604*2*4   256 * 256    32768        256


15G -> 64M
2G -> 64M
1G 32
2

max 1G




# Apparent size + maxium alignment(file_count * block_size) + reserved + extra 5%
ROOTFS_SIZE="$((($FILE_SIZE + $ALIGN_SIZE) * (100 + $BR2_TARGET_ROOTFS_EXT2_RESBLKS  + 5) / 100))"

mkfs.ext4 \
	-d $TARGET_DIR \
	-b $BR2_TARGET_ROOTFS_EXT2_BLKSZ \
	-m $BR2_TARGET_ROOTFS_EXT2_RESBLKS \
	$IMAGE "$(($ROOTFS_SIZE + \
	$ROOTFS_SIZE * $BR2_TARGET_ROOTFS_EXT2_RESBLKS / 100))M"

resize2fs -M $IMAGE
e2fsck -fy $IMAGE
dumpe2fs $IMAGE
