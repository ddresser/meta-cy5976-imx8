SUMMARY = "Minimal initramfs that mounts the root and switches to it"
LICENSE = "MIT"

require recipes-core/images/core-image-minimal-initramfs.bb

PACKAGE_INSTALL += " cryptsetup keyctl-caam e2fsprogs-mke2fs"

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

# mount /proc filesystem
echo "Mounting /proc filesystem"
/bin/mount -t proc proc /proc

# load caam modules
echo "Loading caam modules..."
/sbin/modprobe caam caamkeyblob_desc caam_jr caamhash_desc caamalg_desc

# drop to a shell
exec /bin/sh
EOF
    chmod +x ${IMAGE_ROOTFS}/init
}
