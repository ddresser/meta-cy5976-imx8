# Ensure kernel includes the initramfs

INITRAMFS_IMAGE = "cy5976-initramfs-image"
INITRAMFS_IMAGE_NAME = "${INITRAMFS_IMAGE}-${MACHINE}"

KERNEL_CONFIG_FRAGMENTS += "${THISDIR}/files/initramfs-config.cfg ${THISDIR}/files/caam-config.cfg"

