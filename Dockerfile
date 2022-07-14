#
# makemkv Dockerfile
#
# https://github.com/jlesage/docker-makemkv
#

# Define software versions.
ARG MAKEMKV_VERSION=1.17.1

# Define software download URLs.
ARG MAKEMKV_OSS_URL=https://www.makemkv.com/download/makemkv-oss-${MAKEMKV_VERSION}.tar.gz
ARG MAKEMKV_BIN_URL=https://www.makemkv.com/download/makemkv-bin-${MAKEMKV_VERSION}.tar.gz

# Build MakeMKV.
FROM ubuntu:20.04 AS makemkv
ARG MAKEMKV_OSS_URL
ARG MAKEMKV_BIN_URL
COPY src/makemkv /tmp/makemkv
RUN /tmp/makemkv/build.sh "${MAKEMKV_OSS_URL}" "${MAKEMKV_BIN_URL}"

# Build YAD.
# NOTE: We build a static version to reduce the number of dependencies to be
#       added to the image.
FROM alpine:3.14 AS yad
COPY src/yad/build.sh /build-yad.sh
RUN /build-yad.sh

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.15-v3.5.8

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define working directory.
WORKDIR /tmp

# Install MakeMKV.
COPY --from=makemkv /opt/makemkv /opt/makemkv

# Install Java 8.
RUN \
    add-pkg openjdk8-jre-base && \
    # Removed uneeded stuff.
    rm -r \
        /usr/lib/jvm/java-1.8-openjdk/bin \
        /usr/lib/jvm/java-1.8-openjdk/lib \
        /usr/lib/jvm/java-1.8-openjdk/jre/lib/ext \
        && \
    # Cleanup.
    rm -rf /tmp/* /tmp/.[!.]*

# Install YAD.
COPY --from=yad /tmp/yad-install/usr/bin/yad /usr/bin/

# Install dependencies.
RUN \
    add-pkg \
        wget \
        sed \
        findutils \
        util-linux \
        lsscsi

# Adjust the openbox config.
RUN \
    # Maximize only the main window.
    sed-patch 's/<application type="normal">/<application type="normal" title="MakeMKV BETA">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="MakeMKV BETA">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/makemkv-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Update the default configuration file with the latest beta key.
RUN /opt/makemkv/bin/makemkv-update-beta-key /defaults/settings.conf

# Set environment variables.
ENV APP_NAME="MakeMKV" \
    MAKEMKV_KEY="BETA"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/output"]

# Metadata.
LABEL \
      org.label-schema.name="makemkv" \
      org.label-schema.description="Docker container for MakeMKV" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-makemkv" \
      org.label-schema.schema-version="1.0"
