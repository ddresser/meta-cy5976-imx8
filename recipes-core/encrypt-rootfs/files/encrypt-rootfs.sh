#!/bin/sh

DEVICE="/dev/mmcblk0p3"
MAPPER_NAME="securefs"
MOUNT_POINT="/mnt/secure"
OLD_MOUNT_POINT="/mnt/old"
BOOT_PARTITION="/dev/mmcblk0p1"
OLD_PARTITION="/dev/mmcblk0p2"
BOOT_MOUNT="/mnt/boot"
SESSION_KEY_PATH="/data/caam/session.key"
KEY_BLOB_PATH="$BOOT_MOUNT/secure_key.bb"
KEY_TMP="/tmp/session.key"
ALREADY_ENCRYPTED=0

# Ensure necessary mount points exist
mkdir -p $OLD_MOUNT_POINT $MOUNT_POINT $BOOT_MOUNT /proc /sys /dev

# Mount essential filesystems
echo "Mounting /proc"
/usr/bin/mount -t proc proc /proc
echo "Mounting /sys"
/usr/bin/mount -t sysfs sys /sys
echo "Mounting /dev"
/usr/bin/mount -t devtmpfs devtmpfs /dev

# Load CAAM kernel modules
echo "Loading CAAM modules..."
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

    echo "Copying key blob to persistent storage"
    cp /data/caam/generatedkey.bb $KEY_BLOB_PATH
    sync
    echo "CAAM key stored in boot partition."
}

# Check if the CAAM key exists
if [ ! -f "$KEY_BLOB_PATH" ]; then
    echo "No existing CAAM key found, generating one."
    generate_caam_key
else
    echo "CAAM key found, using existing key."
    ALREADY_ENCRYPTED=1
fi

# Add key to keychain
echo "Adding key to kernel keychain..."
caam-keygen import $KEY_BLOB_PATH session.key
cp "$SESSION_KEY_PATH" "$KEY_TMP"
cat "$KEY_TMP" | keyctl padd logon lukskey: @u

keyctl show @u | grep lukskey:
if [ $? -ne 0 ]; then
    echo "Failed to add key to keyring."
    exit 1
fi

sync
umount $BOOT_MOUNT



# Set up LUKS encryption
echo "Setting up LUKS encryption on $DEVICE..."
SECTOR_SIZE=512
BLOCK_COUNT=$(/usr/sbin/blockdev --getsz "$DEVICE")

dmsetup -v create $MAPPER_NAME --table "0 $BLOCK_COUNT crypt capi:tk(cbc(aes))-plain :36:logon:lukskey: 0 $DEVICE 0 1 sector_size:$SECTOR_SIZE"

if [ $? -ne 0 ]; then
    echo "dmsetup failed. Exiting..."
    exit 1
fi

# create /dev/mapper link if it didn't get created
ln -s /dev/dm-0 /dev/mapper/$MAPPER_NAME

if [ ! -e "/dev/mapper/$MAPPER_NAME" ]; then
    echo "Failed to create mapped device."
    exit 1
fi

# Ensure encrypted device is available
if [ ! -e "/dev/mapper/$MAPPER_NAME" ]; then
    echo "Failed to open encrypted partition."
    exit 1
fi

# Only format if the new partition is not yet encrypted
if [ "$ALREADY_ENCRYPTED" -eq 0 ]; then
    if ! blkid /dev/mapper/$MAPPER_NAME >/dev/null 2>&1; then
        echo "Creating ext4 filesystem on encrypted partition..."
        /usr/sbin/mkfs.ext4 /dev/mapper/$MAPPER_NAME
    fi
fi

# Mount the encrypted filesystem
echo "Mounting encrypted filesystem..."
mount -t ext4 /dev/mapper/$MAPPER_NAME $MOUNT_POINT || {
    echo "Failed to mount encrypted filesystem."
    exit 1
}

# Only copy files if we created a new filesystem
if [ "$ALREADY_ENCRYPTED" -eq 0 ]; then
    echo "Mounting original root filesystem"
    mount -t ext4 $OLD_PARTITION $OLD_MOUNT_POINT

    echo "Copying root filesystem..."
    for i in "$OLD_MOUNT_POINT"/*; do
        case "$(basename "$i")" in
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
fi

# Make mount points for proc, sys, dev
mkdir -p "$MOUNT_POINT"/proc
mkdir -p "$MOUNT_POINT"/dev
mkdir -p "$MOUNT_POINT"/sys

# Switch to new root
echo "Switching to encrypted root filesystem..."
mount --bind /proc "$MOUNT_POINT"/proc
mount --bind /sys "$MOUNT_POINT"/sys
mount --bind /dev "$MOUNT_POINT"/dev
