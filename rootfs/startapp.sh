#!/usr/bin/with-contenv sh
# NOTE: Change the workdir to /storage, as this is the default location when
#       opening files.
# NOTE: $HOME variable needs to be set because the only configuration file
#       location MakeMKV looks for seems to be "$HOME/.MakeMKV"

#export QT_DEBUG_PLUGINS=1

cd /storage
exec env HOME=/config LD_PRELOAD=/opt/makemkv/lib/libwrapper.so /opt/makemkv/bin/makemkv
