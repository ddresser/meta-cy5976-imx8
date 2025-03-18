SUMMARY = "Encrypt the rootfs"
LICENSE = "CLOSED"

SRC_URI = "file://encrypt-rootfs.sh"


do_install() {
    # install the filesystem script
    install -d ${D}/usr
    install -d ${D}/usr/sbin
    install -m 755 ${WORKDIR}/encrypt-rootfs.sh ${D}/usr/sbin
}

FILES:${PN} += "/usr/sbin/encrypt-rootfs.sh"