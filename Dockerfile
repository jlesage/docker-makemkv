#
# makemkv Dockerfile
#
# https://github.com/jlesage/docker-makemkv
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.8-v3.5.1

# Define software versions.
ARG OPENJDK_VERSION=13-ea+9
ARG CCEXTRACTOR_VERSION=0.87

# Define software download URLs.
ARG OPENJDK_URL=https://download.java.net/java/early_access/alpine/9/binaries/openjdk-${OPENJDK_VERSION}_linux-x64-musl_bin.tar.gz
ARG CCEXTRACTOR_URL=https://github.com/CCExtractor/ccextractor/archive/v${CCEXTRACTOR_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

# Install MakeMKV.
ADD makemkv-builder/makemkv.tar.gz /

# Install Java.
RUN \
    add-pkg --virtual build-dependencies \
        curl \
        && \
    mkdir /tmp/jdk/ && \
    # Download and extract.
    curl -# -L "${OPENJDK_URL}" | tar xz --strip 1 -C /tmp/jdk && \
    # Create a minimal Java install.
    mkdir /usr/lib/jvm/ && \
    /tmp/jdk/bin/jlink \
        --compress=2 \
        --module-path /tmp/jdk/jmods \
        --add-modules "$(/tmp/jdk/bin/jdeps /opt/makemkv/share/MakeMKV/blues.jar | grep -v blues.jar | grep -v 'not found' | awk '{ print $4 }'| sort -u | tr '\n' ',')" \
        --output /usr/lib/jvm/jdk \
        && \
    # Removed uneeded stuff.
    rm -r \
        /usr/lib/jvm/jdk/include \
        /usr/lib/jvm/jdk/legal \
        && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Compile and install ccextractor.
RUN \
    add-pkg --virtual build-dependencies \
        build-base \
        cmake \
        zlib-dev \
        curl \
        && \
    # Download and extract.
    mkdir /tmp/ccextractor && \
    curl -# -L "${CCEXTRACTOR_URL}" | tar xz --strip 1 -C /tmp/ccextractor && \
    # Compile.
    mkdir ccextractor/build && \
    cd ccextractor/build && \
    cmake ../src && \
    make && \
    cd ../../ && \
    # Install.
    cp ccextractor/build/ccextractor /usr/bin/ && \
    strip /usr/bin/ccextractor && \
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
