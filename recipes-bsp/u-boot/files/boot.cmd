# show the ahab status
ahab_status

# set memory location for the kernel
setenv kernel_addr_r 0x80400000
# set memory location for the flattened device tree
setenv fdt_addr_r 0x88000000

# load the kernel into memory
# kernel contains initramfs
fatload mmc 0:1 ${kernel_addr_r} Image
# load the device tree into memory
fatload mmc 0:1 ${fdt_addr_r} imx8ulp-evk.dtb

# set boot args
setenv bootargs "console=${console},${baudrate} root=/dev/mmcblk0p2 rootwait rdinit=/init"
# boot the initramfs
booti ${kernel_addr_r} - ${fdt_addr_r}
