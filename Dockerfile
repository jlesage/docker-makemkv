#
# makemkv Dockerfile
#
# https://github.com/jlesage/docker-makemkv
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.8-v3.5.1

# Define software versions.
ARG OPENJDK_VERSION=12-ea+18

# Define software download URLs.
ARG OPENJDK_URL=https://download.java.net/java/early_access/alpine/18/binaries/openjdk-${OPENJDK_VERSION}_linux-x64-musl_bin.tar.gz

# Define working directory.
WORKDIR /tmp

# Install MakeMKV.
ADD makemkv-builder/makemkv.tar.gz /

# Install Java.
RUN \
    add-pkg --virtual build-dependencies \
        curl \
        binutils \
        findutils \
        && \
    mkdir /usr/lib/jvm/ && \
    # Download and extract.
    curl -# -L "${OPENJDK_URL}" | tar xz -C /usr/lib/jvm/ && \
    # Removed uneeded stuff.
    rm -r \
        /usr/lib/jvm/jdk-*/include \
        /usr/lib/jvm/jdk-*/jmods \
        /usr/lib/jvm/jdk-*/legal \
        /usr/lib/jvm/jdk-*/lib/src.zip \
        && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install dependencies.
RUN \
    add-pkg \
        wget \
        sed \
        findutils \
        util-linux \
        lsscsi

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
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-makemkv" \
      org.label-schema.schema-version="1.0"
