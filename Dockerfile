#
# makemkv Dockerfile
#
# https://github.com/jlesage/docker-makemkv
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG MAKEMKV_VERSION=1.18.2

# Define software download URLs.
ARG MAKEMKV_OSS_URL=https://www.makemkv.com/download/makemkv-oss-${MAKEMKV_VERSION}.tar.gz
ARG MAKEMKV_BIN_URL=https://www.makemkv.com/download/makemkv-bin-${MAKEMKV_VERSION}.tar.gz

# Get Dockerfile cross-compilation helpers.
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

# Build MakeMKV libraries needed by the closed source binary.
FROM --platform=$BUILDPLATFORM debian:12 AS makemkv-bin
ARG TARGETPLATFORM
ARG MAKEMKV_OSS_URL
ARG MAKEMKV_BIN_URL
COPY --from=xx / /
COPY src/makemkv-bin /build
RUN /build/build.sh "${MAKEMKV_OSS_URL}" "${MAKEMKV_BIN_URL}"
RUN xx-verify \
    /opt/makemkv/bin/makemkvcon \
    /opt/makemkv/lib/libmakemkv.so.1 \
    /opt/makemkv/lib/libdriveio.so.0 \
    /opt/makemkv/lib/libmmbd.so.0

# Build MakeMKV open source binaries.
FROM --platform=$BUILDPLATFORM alpine:3.19 AS makemkv-oss
ARG TARGETPLATFORM
ARG MAKEMKV_OSS_URL
COPY --from=xx / /
COPY src/makemkv-oss /build
RUN /build/build.sh "${MAKEMKV_OSS_URL}"
RUN xx-verify \
    /tmp/makemkv-install/usr/bin/makemkv \
    /tmp/makemkv-install/usr/bin/mmccextr \
    /tmp/makemkv-install/usr/bin/mmgplsrv

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.19-v4.10.1

ARG DOCKER_IMAGE_VERSION
ARG MAKEMKV_VERSION

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN \
    add-pkg \
        openjdk8-jre-base \
        # For beta key fetching.
        wget \
        sed \
        # For the init script.
        findutils \
        # For optical drive detection.
        lsscsi \
        # For the eject command.
        util-linux-misc \
        sg3_utils \
        # For the GUI.
        qt5-qtbase-x11 \
        adwaita-qt \
        font-croscore

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/makemkv-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=makemkv-bin /opt/makemkv /opt/makemkv
COPY --from=makemkv-oss /tmp/makemkv-install/usr /opt/makemkv

# Update the default configuration file with the latest beta key.
RUN /opt/makemkv/bin/makemkv-update-beta-key /defaults/settings.conf

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "MakeMKV" && \
    set-cont-env APP_VERSION "$MAKEMKV_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Set public environment variables.
ENV \
    MAKEMKV_KEY=BETA \
    MAKEMKV_GUI=1 \
    AUTO_DISC_RIPPER=0 \
    AUTO_DISC_RIPPER_MAKEMKV_PROFILE= \
    AUTO_DISC_RIPPER_EJECT=0 \
    AUTO_DISC_RIPPER_PARALLEL_RIP=0 \
    AUTO_DISC_RIPPER_INTERVAL=5 \
    AUTO_DISC_RIPPER_MIN_TITLE_LENGTH= \
    AUTO_DISC_RIPPER_BD_MODE=mkv \
    AUTO_DISC_RIPPER_DVD_MODE=mkv \
    AUTO_DISC_RIPPER_FORCE_UNIQUE_OUTPUT_DIR=0 \
    AUTO_DISC_RIPPER_NO_GUI_PROGRESS=0

# Define mountable directories.
VOLUME ["/storage"]
VOLUME ["/output"]

# Metadata.
LABEL \
      org.label-schema.name="makemkv" \
      org.label-schema.description="Docker container for MakeMKV" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-makemkv" \
      org.label-schema.schema-version="1.0"
