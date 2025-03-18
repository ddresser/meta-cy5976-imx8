SUMMARY = "Minimal initramfs that mounts the root and switches to it"
LICENSE = "MIT"

require recipes-core/images/core-image-minimal-initramfs.bb

PACKAGE_INSTALL += " cryptsetup keyctl-caam e2fsprogs-mke2fs keyutils encrypt-rootfs"

INITRAMFS_SCRIPTS += "\
		      initramfs-module-e2fs \
		      initramfs-module-rootfs \
		      "

# Define the custom init script creation
ROOTFS_POSTPROCESS_COMMAND += "create_custom_init;"

create_custom_init() {
    cat <<EOF > ${IMAGE_ROOTFS}/init
#!/bin/sh
echo "Hello, World from Initramfs!"

# drop to a shell
exec /bin/sh -l
EOF
    chmod +x ${IMAGE_ROOTFS}/init
}
