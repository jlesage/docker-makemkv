#!/bin/bash

set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

MAKEMKV_VERSION=1.10.6
FFMPEG_VERSION=3.3.2
FDK_AAC_VERSION=0.1.5

MAKEMKV_OSS_URL=http://www.makemkv.com/download/makemkv-oss-${MAKEMKV_VERSION}.tar.gz
MAKEMKV_BIN_URL=http://www.makemkv.com/download/makemkv-bin-${MAKEMKV_VERSION}.tar.gz
FFMPEG_URL=http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz
FDK_AAC_URL=https://github.com/mstorsjo/fdk-aac/archive/v${FDK_AAC_VERSION}.tar.gz

usage() {
    echo "usage: $(basename $0) OUTPUT_DIR [ROOT_EXEC_DIR]

  Arguments:
    OUTPUT_DIR     Directory where the tarball will be copied to.
    ROOT_EXEC_DIR  Root directory where MakeMKV will be located at execution
                   time.  Default: '/opt/makemkv'.
"
}

# Validate script arguments.
if [ -z "$1" ]; then
    echo "ERROR: Output directory must be specified."
    usage
    exit 1
elif [ -n "$2" ] && [[ $2 != /* ]]; then
    echo "ERROR: Invalid root execution directory."
    usage
    exit 1
fi

TARBALL_DIR="$1"
ROOT_EXEC_DIR="${2:-/opt/makemkv}"
BUILD_DIR=/tmp/makemkv-build
INSTALL_BASEDIR=/tmp/makemkv-install
INSTALL_DIR=$INSTALL_BASEDIR$ROOT_EXEC_DIR

mkdir -p "$TARBALL_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

echo "Updating APT cache..."
apt-get update

echo "Installing build prerequisites..."
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    file \
    patchelf \
    build-essential \
    pkg-config \
    dh-autoreconf \
    libc6-dev \
    libssl-dev \
    libexpat1-dev \
    qtbase5-dev

#
# fdk-aac
#
cd "$BUILD_DIR"
echo "Downloading fdk-aac..."
curl -# -L ${FDK_AAC_URL} | tar -xz
echo "Compiling fdk-aac..."
cd fdk-aac-${FDK_AAC_VERSION}
./autogen.sh
./configure --prefix="$BUILD_DIR/fdk-aac" \
            --enable-static \
            --disable-shared \
            --with-pic
make install

#
# ffmpeg
#
cd "$BUILD_DIR"
echo "Downloading ffmpeg..."
curl -# -L ${FFMPEG_URL} | tar -xJ
echo "Compiling ffmpeg..."
cd ffmpeg-${FFMPEG_VERSION}
PKG_CONFIG_PATH="$BUILD_DIR/fdk-aac/lib/pkgconfig" ./configure \
        --prefix="$BUILD_DIR/ffmpeg" \
        --enable-static \
        --disable-shared \
        --enable-pic \
        --enable-libfdk-aac \
        --disable-yasm \
        --disable-doc \
        --disable-programs
make install

#
# MakeMKV OSS
#
cd "$BUILD_DIR"
echo "Downloading MakeMKV OSS..."
curl -# -L ${MAKEMKV_OSS_URL} | tar -xz
echo "Compiling MakeMKV OSS..."
cd makemkv-oss-${MAKEMKV_VERSION}
DESTDIR="$INSTALL_DIR" PKG_CONFIG_PATH="$BUILD_DIR/ffmpeg/lib/pkgconfig" ./configure --prefix=
make install

#
# MakeMKV bin
#
cd "$BUILD_DIR"
echo "Downloading MakeMKV bin..."
curl -# -L ${MAKEMKV_BIN_URL} | tar -xz
echo "Installing MakeMKV bin..."
cd makemkv-bin-${MAKEMKV_VERSION}
patch -p0 < "$SCRIPT_DIR/makemkv-bin-makefile.patch"
DESTDIR="$INSTALL_DIR" make install

echo "Compiling umask wrapper..."
gcc -o $BUILD_DIR/umask_wrapper.so "$SCRIPT_DIR/umask_wrapper.c" -fPIC -shared

echo "Patching ELF of binaries..."
find "$INSTALL_DIR/bin" -type f -exec echo "  -> Setting interpreter of {}..." \; -exec patchelf --set-interpreter "$ROOT_EXEC_DIR/lib/ld-linux-x86-64.so.2" {} \;
find "$INSTALL_DIR/bin" -type f -exec echo "  -> Setting rpath of {}..." \; -exec patchelf --set-rpath '$ORIGIN/../lib' {} \;

QT_PLUGINS="/usr/lib/x86_64-linux-gnu/qt5/plugins/platforms/libqxcb.so"
EXTRA_LIBS="/lib/x86_64-linux-gnu/libnss_compat.so.2 \
            /lib/x86_64-linux-gnu/libnsl.so.1 \
            /lib/x86_64-linux-gnu/libnss_nis.so.2 \
            /lib/x86_64-linux-gnu/libnss_files.so.2 \
            $BUILD_DIR/umask_wrapper.so \
"

# Package library dependencies
echo "Extracting shared library dependencies..."
for BIN in "$INSTALL_DIR/bin/makemkvcon" "$INSTALL_DIR/bin/makemkv" $QT_PLUGINS
do
    DEPS="$(LD_LIBRARY_PATH="$INSTALL_DIR/lib" ldd "$BIN" | grep " => " | cut -d'>' -f2 | sed 's/^[[:space:]]*//' | cut -d'(' -f1 | grep '^/usr\|^/lib')"
    for dep in $DEPS $EXTRA_LIBS
    do
        dep_real="$(realpath "$dep")"
        dep_basename="$(basename "$dep_real")"

        # Skip already-processed libraries.
        [ ! -f "$INSTALL_DIR/lib/$dep_basename" ] || continue

        echo "  -> Found library: $dep"
        cp "$dep_real" "$INSTALL_DIR/lib/"
        while true; do
            [ -L "$dep" ] || break;
            ln -sf "$dep_basename" "$INSTALL_DIR"/lib/$(basename $dep)
            dep="$(readlink -f "$dep")"
        done
    done
done

echo "Adding QT platform plugins..."
mkdir "$INSTALL_DIR/lib/platforms"
for lib in $QT_PLUGINS
do
    base_lib="$(basename $lib)"
    echo "  -> QT Plugin: $lib"
    cp "$lib" "$INSTALL_DIR/lib/"
    ln -s ../$base_lib "$INSTALL_DIR/lib/platforms/$base_lib"
done

echo "Patching ELF of libraries..."
find "$INSTALL_DIR/lib" -type f -name "lib*" -exec echo "  -> Setting rpath of {}..." \; -exec patchelf --set-rpath '$ORIGIN' {} \;

echo "Creating qt.conf..."
echo "[Paths]"                 >  "$INSTALL_DIR/bin/qt.conf"
echo "Prefix = $ROOT_EXEC_DIR" >> "$INSTALL_DIR/bin/qt.conf"
echo "Plugins = lib"           >> "$INSTALL_DIR/bin/qt.conf"

echo "Creating tarball..."
tar -zcf "$TARBALL_DIR/makemkv.tar.gz" -C "$INSTALL_BASEDIR" "${ROOT_EXEC_DIR:1}" --owner=0 --group=0

echo "$TARBALL_DIR/makemkv.tar.gz created successfully!"
