# core-image-base-secure-boot.bbappend

# add the u-boot script to the /boot partition
IMAGE_BOOT_FILES:append = " boot.scr"