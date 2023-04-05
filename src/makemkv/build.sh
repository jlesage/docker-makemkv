#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

FFMPEG_VERSION=4.3.2
FDK_AAC_VERSION=2.0.2
QT_VERSION=5.9.9

FFMPEG_URL=https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz
FDK_AAC_URL=https://github.com/mstorsjo/fdk-aac/archive/v${FDK_AAC_VERSION}.tar.gz
QT_URL=https://download.qt.io/archive/qt/${QT_VERSION%.*}/${QT_VERSION}/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz

usage() {
    echo "usage: $(basename $0) MAKEMKV_OSS_URL MAKEMKV_BIN_URL

  Arguments:
    MAKEMKV_OSS_URL URL where to download the MakeMKV OSS package.
    MAKEMKV_BIN_URL URL where to download the MakeMKV binary package.
"
}

function log {
    echo ">>> $*"
}

# Validate script arguments.
if [ -z "$1" ]; then
    echo "ERROR: MakeMKV OSS URL must be specified."
    usage
    exit 1
elif [ -z "$2" ]; then
    echo "ERROR: MakeMKV binary URL must be specified."
    usage
    exit 1
fi

MAKEMKV_OSS_URL="$1"
MAKEMKV_BIN_URL="$2"

MAKEMKV_ROOT_DIR=/opt/makemkv
mkdir -p "$MAKEMKV_ROOT_DIR"

log "Updating APT cache..."
apt-get update

log "Installing build prerequisites..."
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
    xkb-data \

#
# fdk-aac
#
mkdir /tmp/fdk-aac
log "Downloading fdk-aac..."
curl -# -L -f ${FDK_AAC_URL} | tar -xz --strip 1 -C /tmp/fdk-aac
log "Configuring fdk-aac..."
(
    cd /tmp/fdk-aac && \
    ./autogen.sh && \
    ./configure \
        --prefix=/usr \
        --enable-static \
        --disable-shared \
        --with-pic \
)
log "Compiling fdk-aac..."
make -C /tmp/fdk-aac -j$(nproc)
log "Installing fdk-aac..."
make -C /tmp/fdk-aac install

#
# ffmpeg
#
mkdir /tmp/ffmpeg
log "Downloading ffmpeg..."
curl -# -L -f ${FFMPEG_URL} | tar -xJ --strip 1 -C /tmp/ffmpeg
log "Configuring ffmpeg..."
(
    cd /tmp/ffmpeg && ./configure \
        --prefix=/usr \
        --enable-static \
        --disable-shared \
        --enable-pic \
        --enable-libfdk-aac \
        --disable-x86asm \
        --disable-doc \
        --disable-programs \
)
log "Compiling ffmpeg..."
make -C /tmp/ffmpeg -j$(nproc)
log "Installing ffmpeg..."
make -C /tmp/ffmpeg install

#
# Qt
#
# NOTE: fontconfig is disabled to avoid potential config files
#       incompatibilities.  The version used by the builder may differ from the
#       one used at runtime.
# NOTE: The latest Qt version from the 5.9 branch is used.  Recent Qt versions
#       are using the `statx` system call, which is not whitelisted by default
#       with Docker versions < 8.6.
#
mkdir /tmp/qt5
log "Downloading Qt..."
curl -# -L -f ${QT_URL} | tar -xJ --strip 1 -C /tmp/qt5
log "Configuring Qt..."
# Create the configure options file.
echo "\
-opensource
-confirm-license
-prefix
/usr
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
" > /tmp/qt5/config.opt
# Skip all modules (except qtbase).
find /tmp/qt5 -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | grep qt | grep -v qtbase | xargs -n1 printf "-skip\n%s\n" >> /tmp/qt5/config.opt
(
    cd /tmp/qt5 && ./configure -redo
)
log "Compiling Qt..."
make -C /tmp/qt5 -j$(nproc)
log "Installing Qt..."
make -C /tmp/qt5 -j$(nproc) install

#
# MakeMKV OSS
#
mkdir /tmp/makemkv-oss
log "Downloading MakeMKV OSS..."
curl -# -L -f ${MAKEMKV_OSS_URL} | tar -xz --strip 1 -C /tmp/makemkv-oss
log "Configuring MakeMKV OSS..."
(
    cd /tmp/makemkv-oss && ./configure \
        --prefix=/ \
)
log "Compiling MakeMKV OSS..."
patch -p0 -d /tmp/makemkv-oss < "$SCRIPT_DIR/launch-url.patch"
make -C /tmp/makemkv-oss -j$(nproc)
log "Installing MakeMKV OSS..."
make DESTDIR="$MAKEMKV_ROOT_DIR" -C /tmp/makemkv-oss install
rm -r /opt/makemkv/share/applications

#
# MakeMKV bin
#
mkdir /tmp/makemkv-bin
log "Downloading MakeMKV bin..."
curl -# -L -f ${MAKEMKV_BIN_URL} | tar -xz --strip 1 -C /tmp/makemkv-bin
log "Installing MakeMKV bin..."
patch -p0 -d /tmp/makemkv-bin < "$SCRIPT_DIR/makemkv-bin-makefile.patch"
make DESTDIR="$MAKEMKV_ROOT_DIR" -C /tmp/makemkv-bin install

#
# Chmod Wrapper
#
log "Compiling libwrapper..."
gcc -o /tmp/libwrapper.so "$SCRIPT_DIR/libwrapper.c" -fPIC -shared -ldl
log "Installing chmod wrapper..."
cp -v /tmp/libwrapper.so "$MAKEMKV_ROOT_DIR"/lib/
strip "$MAKEMKV_ROOT_DIR"/lib/libwrapper.so

# Add needed liraries that are not catched by tracking dependencies.  These are
# loaded dynamically via dlopen.
log "Adding extra libraries..."
mkdir -p \
    "$MAKEMKV_ROOT_DIR"/lib/qt5/plugins/platforms
cp -av /usr/plugins/platforms/libqxcb.so "$MAKEMKV_ROOT_DIR"/lib/qt5/plugins/platforms/
cp -av /usr/lib/x86_64-linux-gnu/libcurl.so.4* "$MAKEMKV_ROOT_DIR"/lib/
cp -av /lib/x86_64-linux-gnu/libnss_compat* "$MAKEMKV_ROOT_DIR"/lib/
cp -av /lib/x86_64-linux-gnu/libnsl*so* "$MAKEMKV_ROOT_DIR"/lib/
cp -av /lib/x86_64-linux-gnu/libnss_nis[.-]* "$MAKEMKV_ROOT_DIR"/lib/
cp -av /lib/x86_64-linux-gnu/libnss_files* "$MAKEMKV_ROOT_DIR"/lib/

# Extract dependencies of all binaries and libraries.
log "Extracting shared library dependencies..."
find "$MAKEMKV_ROOT_DIR" -type f -executable -or -name 'lib*.so*' | while read BIN
do
    RAW_DEPS="$(LD_LIBRARY_PATH="$MAKEMKV_ROOT_DIR/lib" ldd "$BIN")"
    echo "Dependencies for $BIN:"
    echo "================================"
    echo "$RAW_DEPS"
    echo "================================"

    if echo "$RAW_DEPS" | grep -q " not found"; then
        echo "ERROR: Some libraries are missing!"
        exit 1
    fi

    LD_LIBRARY_PATH="$MAKEMKV_ROOT_DIR/lib" ldd "$BIN" | (grep " => " || true) | cut -d'>' -f2 | sed 's/^[[:space:]]*//' | cut -d'(' -f1 | while read dep
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
    done
done

log "Patching ELF of binaries..."
find "$MAKEMKV_ROOT_DIR"/bin -type f -executable -exec echo "  -> Setting interpreter of {}..." \; -exec patchelf --set-interpreter "$MAKEMKV_ROOT_DIR/lib/ld-linux-x86-64.so.2" {} ';'
find "$MAKEMKV_ROOT_DIR"/bin -type f -executable -exec echo "  -> Setting rpath of {}..." \; -exec patchelf --set-rpath '$ORIGIN/../lib' {} ';'

log "Patching ELF of libraries..."
find "$MAKEMKV_ROOT_DIR"/lib -maxdepth 1 -type f -name "lib*" -exec echo "  -> Setting rpath of {}..." \; -exec patchelf --set-rpath '$ORIGIN' {} ';'
find "$MAKEMKV_ROOT_DIR"/lib/qt5 -type f -name "lib*" -exec echo "  -> Setting rpath of {}..." \; -exec patchelf --set-rpath "\$ORIGIN:$MAKEMKV_ROOT_DIR/lib" {} ';'

echo "Copying interpreter..."
cp -av /lib/x86_64-linux-gnu/ld-* "$MAKEMKV_ROOT_DIR"/lib/

echo "Creating qt.conf..."
cat << EOF > "$MAKEMKV_ROOT_DIR"/bin/qt.conf
[Paths]
Prefix = $MAKEMKV_ROOT_DIR/lib/qt5
EOF

echo "MakeMKV built successfully."

# vim:ft=sh:ts=4:sw=4:et:sts=4
