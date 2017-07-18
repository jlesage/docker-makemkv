#
# makemkv Dockerfile
#
# https://github.com/jlesage/docker-makemkv
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-v2.0.1

# Define working directory.
WORKDIR /tmp

# Install MakeMKV.
ADD makemkv-builder/makemkv.tar.gz /

# Install dependencies.
RUN \
    add-pkg \
        wget \
        sed \
        findutils \
        util-linux \
        openjdk8-jre-base

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
VOLUME ["/watch"]

# Metadata.
LABEL \
      org.label-schema.name="makemkv" \
      org.label-schema.description="Docker container for MakeMKV" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-makemkv" \
      org.label-schema.schema-version="1.0"
