ARG IMAGEBUILDER
ARG IMAGEBUILDER_WORKDIR="/home/build/openwrt"

FROM ${IMAGEBUILDER} as ext_imagebuilder

FROM debian as updated_config_build
    ARG IMAGEBUILDER_WORKDIR 
    RUN mkdir -p /layer
    WORKDIR /layer
    COPY --from=ext_imagebuilder ${IMAGEBUILDER_WORKDIR}/.config ./
    COPY scripts/ /usr/local/bin/

    ARG CONFIG_TARGET_ROOTFS_PARTSIZE
    RUN update_config.sh CONFIG_TARGET_ROOTFS_PARTSIZE ${CONFIG_TARGET_ROOTFS_PARTSIZE}
    ARG CONFIG_USES_SQUASHFS
    RUN update_config.sh CONFIG_USES_SQUASHFS ${CONFIG_USES_SQUASHFS}
    ARG CONFIG_TARGET_ROOTFS_SQUASHFS
    RUN update_config.sh CONFIG_TARGET_ROOTFS_SQUASHFS n 

    RUN mkdir -p packages-mirror; update_config.sh CONFIG_LOCALMIRROR $(pwd)/packages-mirror
    RUN --mount=type=cache,target=packages-mirror,ro find packages-mirror  | tee .cache_debug

FROM scratch as updated_config
    COPY --from=updated_config_build /layer/* ./

FROM ext_imagebuilder as builder
    RUN set -xe; sudo apt update; sudo apt-get -y install ack vim
    RUN echo :set compatible > ~/.vimrc 
    COPY basic/files files

    COPY --from=updated_config / /

FROM builder as build 
    ARG EXTRA_PACKAGES
    RUN --mount=type=cache,target=packages-mirror,ro \
        set -xe; \
        make image PACKAGES="${EXTRA_PACKAGES}" FILES="files"
    USER root
    RUN --mount=type=cache,target=packages-mirror,rw \
        cp -a dl/* packages-mirror
    RUN set -xe; \ 
        mkdir /output; \
        find ./bin -type f | xargs -I{} cp {} /output/; 

FROM scratch as default
    COPY --from=build /output/ /

