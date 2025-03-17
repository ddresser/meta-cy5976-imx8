DESCRIPTION = "Setup LUKS encrypted partition at first boot"
LICENSE = "MIT"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = "file://luks-init.sh"

do_install() {
    install -m 0755 ${WORKDIR}/luks-init.sh ${D}/usr/local/bin/luks-init.sh
}

FILES:${PN} += "/usr/local/bin/luks-init.sh"
