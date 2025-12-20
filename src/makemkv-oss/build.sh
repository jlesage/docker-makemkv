#!/bin/sh

#
# This script builds the MakeMKV GUI.
#
# NOTE: The MakeMKV Makefile also builds the libraries.  Thus, we need to
#       satisfy dependencies that are not needed by the GUI (e.g. ffmpeg).
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer -DQT_NO_DEBUG_OUTPUT"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++

if [ "$(xx-info march)" = "i386" ]; then
    export LD="$(xx-info)-ld -m elf_i386"
fi

log() {
    echo ">>> $*"
}

MAKEMKV_URL="$1"

if [ -z "$MAKEMKV_URL" ]; then
    log "ERROR: MakeMKV URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    clang \
    llvm \
    make \
    patch \
    qtchooser \
    qt5-qtbase-dev \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    g++ \
    qt5-qtbase-dev \
    openssl-dev \
    expat-dev \
    ffmpeg-dev \

# Make sure tools used to generate code are the ones from the host.
if [ "$(xx-info sysroot)" != "/" ]
then
    ln -sf /usr/bin/moc $(xx-info sysroot)usr/lib/qt5/bin/moc
fi

#
# Download sources.
#

log "Downloading MakeMKV..."
mkdir /tmp/makemkv
curl -# -L -f ${MAKEMKV_URL} | tar xz --strip 1 -C /tmp/makemkv

#
# Compile MakeMKV.
#

MAKEMKV_COMPILED_BINS="\
    out/makemkv \
    out/mmccextr \
    out/mmgplsrv \
"

log "Patching MakeMKV..."
patch -d /tmp/makemkv -p1 < "$SCRIPT_DIR/fix-include.patch"
patch -d /tmp/makemkv -p1 < "$SCRIPT_DIR/launch-url.patch"
patch -d /tmp/makemkv -p1 < "$SCRIPT_DIR/hooks.patch"
patch -d /tmp/makemkv -p1 < "$SCRIPT_DIR/fix-musl-compile.patch"

log "Configuring MakeMKV..."
(
    cd /tmp/makemkv && OBJCOPY=llvm-objcopy ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
)

# FFmpeg was installed only to satisfy the configure part.  The MakeMKV GUI is
# not using it.
xx-apk --no-cache --no-scripts del ffmpeg-dev

log "Compiling MakeMKV..."
make -C /tmp/makemkv -j$(nproc) $MAKEMKV_COMPILED_BINS

log "Installing MakeMKV..."
mkdir -p /tmp/makemkv-install/usr/bin
for BIN in $MAKEMKV_COMPILED_BINS
do
    cp -v /tmp/makemkv/"$BIN" /tmp/makemkv-install/usr/bin/
done

# vim:ft=sh:ts=4:sw=4:et:sts=4
