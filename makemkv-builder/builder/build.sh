#!/bin/bash
#
# NOTE: The latest Qt version from the 5.9 branch is used.  Recent Qt versions
#       are using the `statx` system call, which is not whitelisted by default
#       on Docker versions < 8.6.
#

set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

MAKEMKV_VERSION=1.16.1
FFMPEG_VERSION=4.3.1
FDK_AAC_VERSION=2.0.1
QT_VERSION=5.9.8

MAKEMKV_OSS_URL=https://www.makemkv.com/download/makemkv-oss-${MAKEMKV_VERSION}.tar.gz
MAKEMKV_BIN_URL=https://www.makemkv.com/download/makemkv-bin-${MAKEMKV_VERSION}.tar.gz
FFMPEG_URL=https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz
FDK_AAC_URL=https://github.com/mstorsjo/fdk-aac/archive/v${FDK_AAC_VERSION}.tar.gz
QT_URL=http://download.qt.io/official_releases/qt/5.9/${QT_VERSION}/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz

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

rm -rf "$INSTALL_DIR"
mkdir -p "$TARBALL_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

echo "Updating APT cache..."
apt-get update

# NOTE: zlib is needed by Qt and MakeMKV.
# NOTE: xkb-data is needed for Qt to detect the correct XKB config path.
echo "Installing build prerequisites..."
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    file \
    patchelf \
    build-essential \
    pkg-config \
    dh-autoreconf \
    python \
    libc6-dev \
    libssl-dev \
    libexpat1-dev \
    zlib1g-dev \
    libdrm-dev \
    libxcb1-dev \
    libx11-dev \
    libx11-xcb-dev \
    xkb-data

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
make -j$(nproc) install

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
make -j$(nproc) install

#
# Qt
#
# NOTE: fontconfig is disabled to avoid potential config files
#       incompatibilities.  The version used by the builder may differ from the
#       one used at runtime.
#
cd "$BUILD_DIR"
echo "Downloading qt..."
mkdir qt-src
curl -# -L ${QT_URL} | tar -xJ --strip 1 -C qt-src
echo "Compiling qt..."
cd qt-src
# Create the configure options file.
echo "\
-opensource
-confirm-license
-prefix
$BUILD_DIR/qt
-sysconfdir
/etc/xdg
-release
-strip
-ltcg
-no-pch
-nomake
tools
-nomake
tests
-nomake
examples
-sql-sqlite
-no-sql-odbc
-system-zlib
-qt-freetype
-qt-pcre
-qt-libpng
-qt-libjpeg
-qt-xcb
-qt-xkbcommon-x11
-qt-harfbuzz
-qt-sqlite
-no-fontconfig
-no-compile-examples
-no-cups
-no-iconv
-no-opengl
-no-qml-debug
-no-feature-xml
-no-feature-testlib
-no-openssl
" > config.opt
# Skip all modules (except qtbase).
find . -maxdepth 1 -type d -printf "%f\n" | grep qt | grep -v qtbase | xargs -n1 printf "-skip\n%s\n" >> config.opt
# Run configure with new options.
./configure -redo
# Compile.
make -j$(nproc)
make -j$(nproc) install

#
# MakeMKV OSS
#
cd "$BUILD_DIR"
echo "Downloading MakeMKV OSS..."
mkdir makemkv-oss
curl -# -L ${MAKEMKV_OSS_URL} | tar -xz --strip 1 -C makemkv-oss
echo "Compiling MakeMKV OSS..."
cd makemkv-oss
patch -p0 < "$SCRIPT_DIR/launch-url.patch"
DESTDIR="$INSTALL_DIR" PKG_CONFIG_PATH="$BUILD_DIR/ffmpeg/lib/pkgconfig:$BUILD_DIR/qt/lib/pkgconfig" ./configure --prefix=
make -j$(nproc) install

#
# MakeMKV bin
#
cd "$BUILD_DIR"
echo "Downloading MakeMKV bin..."
mkdir makemkv-bin
curl -# -L ${MAKEMKV_BIN_URL} | tar -xz --strip 1 -C makemkv-bin
echo "Installing MakeMKV bin..."
cd makemkv-bin
patch -p0 < "$SCRIPT_DIR/makemkv-bin-makefile.patch"
DESTDIR="$INSTALL_DIR" make install

#
# Umask Wrapper
#
echo "Compiling umask wrapper..."
gcc -o "$BUILD_DIR"/umask_wrapper.so "$SCRIPT_DIR/umask_wrapper.c" -fPIC -shared
echo "Installing umask wrapper..."
cp -v "$BUILD_DIR"/umask_wrapper.so "$INSTALL_DIR/lib/"

#
# QT Plugins
#
echo "Adding QT platform plugins..."
QT_PLUGINS="$BUILD_DIR/qt/plugins/platforms/libqxcb.so"
mkdir "$INSTALL_DIR/lib/platforms"
for lib in $QT_PLUGINS
do
    base_lib="$(basename $lib)"
    echo "  -> QT Plugin: $lib"
    cp "$lib" "$INSTALL_DIR/lib/"
    ln -s ../$base_lib "$INSTALL_DIR/lib/platforms/$base_lib"
done

#
# curl libraries
#
echo "Adding libcurl..."
cp -av /usr/lib/x86_64-linux-gnu/libcurl.so.4* "$INSTALL_DIR/lib/"

echo "Patching ELF of binaries..."
find "$INSTALL_DIR"/bin -type f -executable -exec echo "  -> Setting interpreter of {}..." \; -exec patchelf --set-interpreter "$ROOT_EXEC_DIR/lib/ld-linux-x86-64.so.2" {} \;
find "$INSTALL_DIR"/bin -type f -executable -exec echo "  -> Setting rpath of {}..." \; -exec patchelf --set-rpath '$ORIGIN/../lib' {} \;

EXTRA_LIBS="/lib/x86_64-linux-gnu/libnss_compat.so.2 \
            /lib/x86_64-linux-gnu/libnsl.so.1 \
            /lib/x86_64-linux-gnu/libnss_nis.so.2 \
            /lib/x86_64-linux-gnu/libnss_files.so.2 \
"

# Package library dependencies
echo "Extracting shared library dependencies..."
find "$INSTALL_DIR" -type f -executable -or -name 'lib*.so*' | while read BIN
do
    RAW_DEPS="$(LD_LIBRARY_PATH="$INSTALL_DIR/lib:$BUILD_DIR/jdk/lib/jli:$BUILD_DIR/qt/lib" ldd "$BIN")"
    echo "Dependencies for $BIN:"
    echo "================================"
    echo "$RAW_DEPS"
    echo "================================"

    if echo "$RAW_DEPS" | grep -q " not found"; then
        echo "ERROR: Some libraries are missing!"
        exit 1
    fi

    DEPS="$(LD_LIBRARY_PATH="$INSTALL_DIR/lib:$BUILD_DIR/qt/lib" ldd "$BIN" | (grep " => " || true) | cut -d'>' -f2 | sed 's/^[[:space:]]*//' | cut -d'(' -f1)"
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

echo "Patching ELF of libraries..."
find "$INSTALL_DIR" \
    -type f \
    -name "lib*" \
    -exec echo "  -> Setting rpath of {}..." \; -exec patchelf --set-rpath '$ORIGIN' {} \;

echo "Creating qt.conf..."
echo "[Paths]"                 >  "$INSTALL_DIR/bin/qt.conf"
echo "Prefix = $ROOT_EXEC_DIR" >> "$INSTALL_DIR/bin/qt.conf"
echo "Plugins = lib"           >> "$INSTALL_DIR/bin/qt.conf"

echo "Creating tarball..."
tar -zcf "$TARBALL_DIR/makemkv.tar.gz" -C "$INSTALL_BASEDIR" "${ROOT_EXEC_DIR:1}" --owner=0 --group=0

echo "$TARBALL_DIR/makemkv.tar.gz created successfully!"

# vim:ft=sh:ts=4:sw=4:et:sts=4
