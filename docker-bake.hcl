target "vanila" {
    args = { 
        IMAGEBUILDER = "docker.io/openwrtorg/imagebuilder:bcm27xx-bcm2711-openwrt-21.02"
    }
    output = ["build/vanila/bin"]
}

target "example" {
    inherits = ["vanila"]
    args = {
        EXTRA_PACKAGES = "kmod-r8169 tune2fs resize2fs luci docker luci-app-dockerman parted git-http"
    }
    contexts = {
        bundle = "example"
    }
    output = ["build/example/bin"]
}
