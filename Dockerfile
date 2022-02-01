# syntax=docker/dockerfile-upstream:master

ARG IMAGEBUILDER
ARG IMAGEBUILDER_WORKDIR="/home/build/openwrt"

FROM ${IMAGEBUILDER} as ext_imagebuilder

FROM busybox AS build-helpers
RUN touch /empty.file; mkdir /empty.dir

FROM docker.io/library/python:3-slim as updated_config_build
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
    RUN update_config.sh CONFIG_TARGET_ROOTFS_SQUASHFS ${CONFIG_TARGET_ROOTFS_SQUASHFS}

    RUN update_config.sh CONFIG_LOCALMIRROR ${IMAGEBUILDER_WORKDIR}/packages-mirror
    RUN --mount=type=cache,target=packages-mirror,ro find packages-mirror  | tee .cache_debug

FROM scratch as bundle
    COPY --from=build-helpers /empty.file .config
    COPY --from=build-helpers /empty.dir files

FROM scratch as files
    COPY --from=bundle /files/ ./
FROM scratch as config_override
    COPY --from=bundle /.config ./

FROM docker.io/library/python:3-slim as compute_config_override
    ARG IMAGEBUILDER_WORKDIR 
    RUN mkdir -p /build
    WORKDIR /build
    COPY scripts/ /usr/local/bin/

    COPY --from=ext_imagebuilder ${IMAGEBUILDER_WORKDIR}/.config ./base.config
    COPY --from=config_override .config ./override.config
    RUN merge_config.py base.config override.config final.config

FROM scratch as config
    COPY --from=compute_config_override /build/final.config ./.config

FROM ext_imagebuilder as builder
    RUN set -xe; sudo apt update; sudo apt-get -y install ack vim
    RUN echo :set compatible > ~/.vimrc
    
    RUN mkdir files/
    COPY --from=files * files/
    COPY --from=config .config ./

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

