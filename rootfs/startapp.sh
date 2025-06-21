#!/bin/sh
# NOTE: Change the workdir to /storage, as this is the default location when
#       opening files.
# NOTE: $HOME variable needs to be set because the only configuration file
#       location MakeMKV looks for seems to be "$HOME/.MakeMKV"

#export QT_DEBUG_PLUGINS=1
export HOME=/config

# Added to avoid the following error message:
#   MESA-LOADER: failed to open swrast: Error loading shared library
#   /usr/lib/xorg/modules/dri/swrast_dri.so: No such file or directory
#   (search paths /usr/lib/xorg/modules/dri, suffix _dri)
# We could instead install `mesa-dri-gallium`, but this increases the image
# size a lot.
export QT_QPA_PLATFORM=xcb
export QT_XCB_GL_INTEGRATION=none

DEBUG_ARGS=
if is-bool-val-true "${CONTAINER_DEBUG:-0}"; then
    mkdir -p /config/log/makemkv
    DEBUG_ARGS="debug /config/log/makemkv/debug.txt"
fi

cd /storage
exec /opt/makemkv/bin/makemkv $DEBUG_ARGS -std

# vim:ft=sh:ts=4:sw=4:et:sts=4
