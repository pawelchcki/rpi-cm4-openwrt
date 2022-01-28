target "default" {
    args = { 
        IMAGEBUILDER = "docker.io/openwrtorg/imagebuilder:bcm27xx-bcm2711-openwrt-21.02"
        EXTRA_PACKAGES = "kmod-r8169 tune2fs resize2fs dockerd luci luci-app-dockerman parted"
        CONFIG_USES_SQUASHFS = "n"
        CONFIG_TARGET_ROOTFS_PARTSIZE = "300"
        CONFIG_TARGET_ROOTFS_SQUASHFS = "n"
    }
    output = ["build/bin"]
}

target "builder" {
    inherits = ["default"]
    target = "builder"
    output = ["type=docker"]
    tags = ["builder"]
}

target "config" {
    inherits = ["default"]
    target = "updated_config"
    output = ["build/config"]
}
