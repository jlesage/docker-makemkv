#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

export CC=$(xx-info)-gcc
export CXX=$(xx-info)-g++

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

FFMPEG_VERSION=5.1.6
FDK_AAC_VERSION=2.0.3

FFMPEG_URL=https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz
FDK_AAC_URL=https://github.com/mstorsjo/fdk-aac/archive/v${FDK_AAC_VERSION}.tar.gz

MAKEMKV_ROOT_DIR=/opt/makemkv

function log {
    echo ">>> $*"
}

MAKEMKV_OSS_URL="$1"
MAKEMKV_BIN_URL="$2"

if [ -z "$MAKEMKV_OSS_URL" ]; then
    log "ERROR: MakeMKV OSS URL missing."
    exit 1
fi

if [ -z "$MAKEMKV_BIN_URL" ]; then
    log "ERROR: MakeMKV BIN URL missing."
    exit 1
fi

#
# Install required packages.
#

log "Updating APT cache..."
apt-get update

log "Installing build prerequisites..."
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    build-essential \
    patchelf \
    pkg-config \
    dh-autoreconf \
    nasm \

xx-apt-get install -y --no-install-recommends \
    binutils \
    gcc \
    g++ \
    libgcc-12-dev \
    libstdc++-12-dev \
    libc6-dev \
    libssl-dev \
    libexpat1-dev \
    zlib1g-dev \

#
# Download sources.
#

log "Downloading fdk-aac..."
mkdir /tmp/fdk-aac
curl -# -L -f ${FDK_AAC_URL} | tar -xz --strip 1 -C /tmp/fdk-aac

log "Downloading ffmpeg..."
mkdir /tmp/ffmpeg
curl -# -L -f ${FFMPEG_URL} | tar -xJ --strip 1 -C /tmp/ffmpeg

log "Downloading MakeMKV OSS..."
mkdir /tmp/makemkv-oss
curl -# -L -f ${MAKEMKV_OSS_URL} | tar -xz --strip 1 -C /tmp/makemkv-oss

log "Downloading MakeMKV bin..."
mkdir /tmp/makemkv-bin
curl -# -L -f ${MAKEMKV_BIN_URL} | tar -xz --strip 1 -C /tmp/makemkv-bin

#
# Compile fdk-aac.
#

log "Configuring fdk-aac..."
(
    cd /tmp/fdk-aac && \
    ./autogen.sh && \
    ./configure \
        --build=$(TARGETPLATFORM= xx-info) \
        --host=$(xx-info) \
        --prefix=/usr \
        --enable-static \
        --disable-shared \
        --with-pic \
)

log "Compiling fdk-aac..."
make -C /tmp/fdk-aac -j$(nproc)

log "Installing fdk-aac..."
make DESTDIR=$(xx-info sysroot) -C /tmp/fdk-aac install

#
# Compile ffmpeg.
#

log "Configuring ffmpeg..."
(
    CROSS_FLAGS=
    if xx-info is-cross; then
        CROSS_FLAGS="\
            --enable-cross-compile \
            --cross-prefix=$(xx-info)- \
            --arch=$(xx-info pkg-arch) \
        "
    fi

    cd /tmp/ffmpeg && PKG_CONFIG_PATH=$(xx-info sysroot)/usr/lib/pkgconfig ./configure \
        --cc=$(xx-info)-gcc \
        $CROSS_FLAGS \
        --target-os=linux \
        --prefix=/usr \
        --enable-static \
        --disable-shared \
        --enable-pic \
        --enable-libfdk-aac \
        --disable-doc \
        --disable-programs \
)

log "Compiling ffmpeg..."
make -C /tmp/ffmpeg -j$(nproc)

log "Installing ffmpeg..."
make DESTDIR=$(xx-info sysroot) -C /tmp/ffmpeg install

#
# Compile MakeMKV OSS.
#

log "Configuring MakeMKV OSS..."
(
    cd /tmp/makemkv-oss && OBJCOPY=$(xx-info)-objcopy ./configure \
        --prefix=/ \
        --disable-gui \
)

log "Compiling MakeMKV OSS..."
make -C /tmp/makemkv-oss -j$(nproc)

log "Installing MakeMKV OSS..."
make DESTDIR="$MAKEMKV_ROOT_DIR" -C /tmp/makemkv-oss install
rm -v \
    /opt/makemkv/bin/mmccextr \
    /opt/makemkv/bin/mmgplsrv \

#
# Compile MakeMKV bin.
#

log "Patching MakeMKV bin..."
patch -p1 -d /tmp/makemkv-bin < "$SCRIPT_DIR/makemkv-bin-makefile.patch"

log "Installing MakeMKV bin..."
mkdir /tmp/makemkv-bin/tmp && touch /tmp/makemkv-bin/tmp/eula_accepted
make DESTDIR="$MAKEMKV_ROOT_DIR" PREFIX=/ -C /tmp/makemkv-bin install

#
# Compile libwrapper.
#

log "Compiling libwrapper..."
$(xx-info)-gcc -o /tmp/libwrapper.so "$SCRIPT_DIR/libwrapper.c" -fPIC -shared -ldl 

log "Installing libwrapper..."
cp -v /tmp/libwrapper.so "$MAKEMKV_ROOT_DIR"/lib/
$(xx-info)-strip "$MAKEMKV_ROOT_DIR"/lib/libwrapper.so

#
# Extract all dependencies.
#

# Setup LDD.
LDD=ldd
if xx-info is-cross; then
    LDD="$(xx-info)-ldd"
    #export CT_XLDD_VERBOSE=1
    export CT_XLDD_LIBRARY_PATH="$MAKEMKV_ROOT_DIR/lib:/usr/lib/$(xx-info)"
    ln -sv "$SCRIPT_DIR/cross-compile-ldd" "$(dirname "$(which "$(xx-info)-gcc")")/$(xx-info)-ldd"
fi

# Add needed liraries that are not catched by tracking dependencies.  These are
# loaded dynamically via dlopen.
log "Adding extra libraries..."
find "$(xx-info sysroot)"usr/lib -name "libcurl.so.4*" -exec cp -av {} "$MAKEMKV_ROOT_DIR"/lib/ ';'
if [ -z "$(ls -l "$MAKEMKV_ROOT_DIR"/lib/libcurl.so.4*)" ]; then
    log "ERROR: Could not find libcurl."
    exit 1
fi

log "Extracting shared library dependencies..."
find "$MAKEMKV_ROOT_DIR" -type f -executable -or -name 'lib*.so*' | while read BIN
do
    echo "Dependencies for $BIN:"
    RAW_DEPS="$(LD_LIBRARY_PATH="$MAKEMKV_ROOT_DIR/lib" "$LDD" "$BIN")"
    echo "================================"
    echo "$RAW_DEPS"
    echo "================================"

    if echo "$RAW_DEPS" | grep -q " not found"; then
        echo "ERROR: Some libraries are missing!"
        exit 1
    fi

    LD_LIBRARY_PATH="$MAKEMKV_ROOT_DIR/lib" "$LDD" "$BIN" | (grep " => " || true) | cut -d'>' -f2 | sed 's/^[[:space:]]*//' | cut -d'(' -f1 | while read dep
    do
        dep_real="$(realpath "$dep")"
        dep_basename="$(basename "$dep_real")"

        # Skip already-processed libraries.
        [ ! -f "$MAKEMKV_ROOT_DIR/lib/$dep_basename" ] || continue

        echo "  -> Found library: $dep"
        cp "$dep_real" "$MAKEMKV_ROOT_DIR/lib/"
        while true; do
            [ -L "$dep" ] || break;
            ln -sf "$dep_basename" "$MAKEMKV_ROOT_DIR"/lib/$(basename $dep)
            dep="$(readlink -f "$dep")"
        done

        dep_fname="$(basename "$dep")"
        if [[ "$dep_fname" =~ ^ld-* ]]; then
            echo "$dep_fname" > /tmp/interpreter_fname
            echo "    -> This is the interpreter."
        fi
    done
done

INTERPRETER_FNAME=
if xx-info is-cross; then
    if [ -f /tmp/interpreter_fname ]; then
        INTERPRETER_FNAME="$(cat /tmp/interpreter_fname)"
    fi
    if [ -z "$INTERPRETER_FNAME" ]; then
        echo "ERROR: Interpreter not found!"
        exit 1
    fi
else
    INTERPRETER_FNAME=ld-linux-x86-64.so.2
    echo "Copying interpreter..."
    cp -v /lib/x86_64-linux-gnu/"$INTERPRETER_FNAME" "$MAKEMKV_ROOT_DIR"/lib/"$INTERPRETER_FNAME"
fi

log "Patching ELF of binaries..."
find "$MAKEMKV_ROOT_DIR"/bin -type f -executable -exec echo "  -> Setting interpreter of {}..." ';' -exec patchelf --set-interpreter "$MAKEMKV_ROOT_DIR/lib/$INTERPRETER_FNAME" {} ';'
find "$MAKEMKV_ROOT_DIR"/bin -type f -executable -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath '$ORIGIN/../lib' {} ';'

log "Patching ELF of libraries..."
find "$MAKEMKV_ROOT_DIR"/lib -maxdepth 1 -type f -name "lib*" -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath '$ORIGIN' {} ';'

echo "Content of $MAKEMKV_ROOT_DIR:"
find "$MAKEMKV_ROOT_DIR"

echo "MakeMKV built successfully."

# vim:ft=sh:ts=4:sw=4:et:sts=4
