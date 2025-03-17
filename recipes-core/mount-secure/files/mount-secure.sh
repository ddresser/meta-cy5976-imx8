#!/bin/sh

DEVICE="/dev/mmcblk0p3"
MAPPER_NAME="securefs"
MOUNT_POINT="/mnt/secure"
TAGGED_KEY="/data/caam/secure_key"
KEY_ID="logkey:"

# Ensure the mount point exists
mkdir -p $MOUNT_POINT /data/caam

# Function to generate a new CAAM key if it doesn’t exist
generate_caam_key() {
    echo "Generating CAAM key..."
    caam-keygen create fromTextkey ecb -t 0123456789abcdef
    cp /data/caam/fromTextkey $TAGGED_KEY
    cat $TAGGED_KEY | keyctl padd logon $KEY_ID @s
}

# Ensure the CAAM key exists
if [ ! -f $TAGGED_KEY ]; then
    generate_caam_key
else
    echo "CAAM key found, using existing key."
    cat $TAGGED_KEY | keyctl padd logon $KEY_ID @s
fi

# Check if the partition is already encrypted with LUKS
if ! cryptsetup isLuks $DEVICE; then
    echo "Setting up LUKS encryption on $DEVICE..."
    cryptsetup luksFormat -q --type luks2 --cipher aes-cbc-essiv:sha256 --key-size 256 \
        --key-file <(cat $TAGGED_KEY) $DEVICE
fi

# Open the encrypted partition
echo "Unlocking encrypted partition..."
cryptsetup open --type luks2 --key-file <(cat $TAGGED_KEY) $DEVICE $MAPPER_NAME

# Ensure filesystem exists, otherwise format it
if [ ! -e "/dev/mapper/$MAPPER_NAME" ]; then
    echo "Failed to open encrypted partition."
    exit 1
fi

if ! blkid /dev/mapper/$MAPPER_NAME >/dev/null 2>&1; then
    echo "Creating ext4 filesystem on encrypted partition..."
    mkfs.ext4 /dev/mapper/$MAPPER_NAME
fi

# Mount the filesystem
echo "Mounting encrypted filesystem..."
mount -t ext4 /dev/mapper/$MAPPER_NAME $MOUNT_POINT

echo "Secure filesystem mounted at $MOUNT_POINT"
