#!/bin/sh

DEVICE="/dev/mmcblk0p3"
MAPPER_NAME="securefs"
MOUNT_POINT="/mnt/secure"
OLD_MOUNT_POINT="/mnt/old"
BOOT_PARTITION="/dev/mmcblk0p1"
OLD_PARTITION="/dev/mmcblk0p2"
BOOT_MOUNT="/mnt/boot"
ROOT_PARTITION="/dev/mmcblk0p2"
KEY_BLOB_PATH="$BOOT_MOUNT/secure_key.blob"
KEY_TMP="/tmp/secure_key"

# Ensure necessary mount points exist
mkdir -p $OLD_MOUNT_POINT $MOUNT_POINT $BOOT_MOUNT /proc /sys /dev

# Mount essential filesystems
echo "Mounting /proc"
/usr/bin/mount -t proc proc /proc
echo "Mounting /sys"
/usr/bin/mount -t sysfs sys /sys
echo "Mounting /dev"
/usr/bin/mount -t devtmpfs devtmpfs /dev

# load caam kernel modules
echo "Loading caam modules..."
/usr/sbin/modprobe caam
/usr/sbin/modprobe caam_jr
/usr/sbin/modprobe caamkeyblob_desc

# Mount the boot partition to check for the key
mount $BOOT_PARTITION $BOOT_MOUNT || {
    echo "Failed to mount boot partition."
    exit 1
}

# Function to generate a new CAAM key and save it to the boot partition
generate_caam_key() {
    echo "Generating new CAAM key..."
    
    /usr/bin/caam-keygen create generatedkey ecb -s 16
    if [ ! -f "/data/caam/generatedkey" ]; then
        echo "Failed to generate CAAM key."
        exit 1
    fi

    cp /data/caam/generatedkey $KEY_BLOB_PATH
    sync
    echo "CAAM key stored in boot partition."
}

# Check if the CAAM key exists
if [ ! -f "$KEY_BLOB_PATH" ]; then
    echo "No existing CAAM key found, generating one."
    generate_caam_key
else
    echo "CAAM key found, using existing key."
fi

# Copy the key for use
cp $KEY_BLOB_PATH $KEY_TMP
sync
umount $BOOT_MOUNT

# Check if the partition is already encrypted
if ! /usr/sbin/cryptsetup isLuks $DEVICE; then
    echo "Setting up LUKS encryption on $DEVICE..."
    /usr/sbin/cryptsetup luksFormat -q --type luks2 --cipher aes-cbc-essiv:sha256 --key-size 256 \
        --key-file $KEY_TMP $DEVICE
fi

# Open the encrypted partition
echo "Unlocking encrypted partition..."
/usr/sbin/cryptsetup open --type luks2 --key-file $KEY_TMP $DEVICE $MAPPER_NAME

# Ensure encrypted device is available
if [ ! -e "/dev/mapper/$MAPPER_NAME" ]; then
    echo "Failed to open encrypted partition."
    exit 1
fi

# Format the encrypted partition if it's not already formatted
if ! blkid /dev/mapper/$MAPPER_NAME >/dev/null 2>&1; then
    echo "Creating ext4 filesystem on encrypted partition..."
    /usr/sbin/mkfs.ext4 /dev/mapper/$MAPPER_NAME
fi

# Mount the encrypted filesystem
echo "Mounting encrypted filesystem..."
mount -t ext4 /dev/mapper/$MAPPER_NAME $MOUNT_POINT || {
    echo "Failed to mount encrypted filesystem."
    exit 1
}

# Mount the unencrypted root filesystem
echo "Mounting original root filesystem"
mount -t ext4 $OLD_PARTITION $OLD_MOUNT_POINT

# Copy root filesystem to the encrypted partition
echo "Copying root filesystem..."
for i in $OLD_MOUNT_POINT/*; do
    case "$(basename $i)" in
        dev|sys|proc)
            echo "Skipping $i"
            continue
            ;;
        *)
            echo "Copying $i to $MOUNT_POINT"
            cp -a "$i" "$MOUNT_POINT/"
            ;;
    esac
done

# Make mount points for proc, sys, dev
mkdir -p $MOUNT_POINT/proc
mkdir -p $MOUNT_POINT/dev
mkdir -p $MOUNT_POINT/sys

sync

# Switch to new root
echo "Switching to encrypted root filesystem..."
mount --bind /proc $MOUNT_POINT/proc
mount --bind /sys $MOUNT_POINT/sys
mount --bind /dev $MOUNT_POINT/dev

#exec /usr/sbin/switch_root $MOUNT_POINT /sbin/init
