FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
LICENSE = "CLOSED"
#DEPENDS += "u-boot-mkimage-native"
#inherit deploy

SRC_URI += " file://boot.cmd "
SRC_URI += " file://imx8ulp_evk_defconfig.patch;patchdir=${S} "
	    
UBOOT_ENV = "boot"
UBOOT_ENV_SUFFIX = "scr"

# Install boot.scr to the image if it was generated
do_install:append () {
    if [ -f ${WORKDIR}/boot.scr ]; then
        echo "Installing boot.scr in root filesystem"
        install -d ${D}/boot
        install -m 0644 ${WORKDIR}/boot.scr ${D}/boot/
    else
	echo "ERROR: boot.scr not found!"
    fi
}

# Deploy boot.scr to the deploy directory
do_deploy:append () {
    if [ -f ${WORKDIR}/boot.scr ]; then
        install -m 0644 ${WORKDIR}/boot.scr ${DEPLOYDIR}/
    fi
}
