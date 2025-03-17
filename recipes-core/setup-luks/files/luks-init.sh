#!/bin/sh
PARTITION="/dev/mmcblk0p3"
MAPPER_NAME="encrypted"
MOUNT_POINT="/mnt/encrypted"

# Check if LUKS is already set up
if cryptsetup isLuks $PARTITION; then
    echo "LUKS partition already initialized."
    exit 0
fi

# Format as LUKS
echo "Creating LUKS partition..."
echo -n "mysecurepassphrase" | cryptsetup luksFormat --type luks2 $PARTITION -q

# Open LUKS partition
echo "Opening LUKS partition..."
echo -n "mysecurepassphrase" | cryptsetup open $PARTITION $MAPPER_NAME

# Create filesystem
mkfs.ext4 /dev/mapper/$MAPPER_NAME

# Mount it
mkdir -p $MOUNT_POINT
mount /dev/mapper/$MAPPER_NAME $MOUNT_POINT

# Configure /etc/crypttab for auto-unlocking
echo "$MAPPER_NAME UUID=$(blkid -s UUID -o value $PARTITION) none luks" >> /etc/crypttab

# Configure /etc/fstab for auto-mount
echo "/dev/mapper/$MAPPER_NAME $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab

echo "LUKS setup complete!"
