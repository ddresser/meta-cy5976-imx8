

LICENSE = "CLOSED"

require recipes-core/images/core-image-minimal-initramfs.bb

PACKAGE_INSTALL += " cryptsetup keyctl-caam e2fsprogs-mke2fs"

addtask image_complete after do_rootfs before do_build

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"



