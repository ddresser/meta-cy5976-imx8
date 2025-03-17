DESCRIPTION = "Recipe to install and start mount-secure.service"
LICENSE = "CLOSED"

SRC_URI = "file://mount-secure.service \
           file://mount-secure.sh"

inherit systemd

SYSTEMD_SERVICE_${PN} = "mount-secure.service"

do_install() {
    # Install the systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 644 ${WORKDIR}/mount-secure.service ${D}${systemd_system_unitdir}

    # Install the shell script
    install -d ${D}/usr/local/bin
    install -m 755 ${WORKDIR}/mount-secure.sh ${D}/usr/local/bin
}

# Explicitly list all installed files
FILES:${PN} += "${systemd_system_unitdir}/mount-secure.service"
FILES:${PN} += "/usr/local/bin/mount-secure.sh"

# Ensure systemd dependency is listed
RDEPENDS:${PN} += "systemd"

# Enable the service to start on boot
SYSTEMD_AUTO_ENABLE:${PN} = "enable"