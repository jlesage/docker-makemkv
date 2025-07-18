#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id
if [ ! -f /config/machine-id ]; then
    echo "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /config/machine-id
fi

mkdir -p "$XDG_CONFIG_HOME"

# Upgrade previous installations.
[ ! -f /config/QtProject.conf ] || mv -v /config/QtProject.conf "$XDG_CONFIG_HOME"/

# If config folder empty, copy all XML profiles so they can be easily
# copied and edited.
#if [ ! -d /config/data ]; then
#    mkdir /config/data
#    find /opt/makemkv/share/MakeMKV/ \
#        -name "*.xml" \
#        -execdir cp {} /config/data/{}.example \;    
#fi

# Copy default config if needed.
if [ ! -f /config/settings.conf ] || [ "$(stat -c "%s" /config/settings.conf)" -eq 0 ]; then
    cp -v /defaults/settings.conf /config/
fi
[ -f "$XDG_CONFIG_HOME"/QtProject.conf ] || cp -v /defaults/QtProject.conf "$XDG_CONFIG_HOME"/

# Copy example hooks if needed.
[ -d /config/hooks ] || cp -rv /defaults/hooks /config/hooks

# Make sure the data directory is correctly set.
if grep -q "^[ \t]*app_DataDir[ \t]*=" /config/settings.conf; then
    sed -i 's|^[ \t]*app_DataDir[ \t]*=.*|app_DataDir = "/config/data"|' /config/settings.conf
else
    sed -i '${/^$/d}' /config/settings.conf
    echo 'app_DataDir = "/config/data"' >> /config/settings.conf
fi

# Create link for MakeMKV config directory.
# The only configuration location MakeMKV looks for seems to be
# "$HOME/.MakeMKV".
# NOTE: Make sure to re-create the link. The `/config` might have been restored
#       from a backup, so the symlink might no longer be one.
rm -rf /config/.MakeMKV
ln -s /config /config/.MakeMKV

# Make sure the data directory exists.
mkdir -p /config/data

# Setup MakeMKV license key.
case  "${MAKEMKV_KEY:-UNSET}" in
    UNSET)
        # Nothing to do.
        ;;
    BETA)
        echo "checking for new beta key..."
        set +e
        /opt/makemkv/bin/makemkv-update-beta-key /config/settings.conf
        if [ "$?" -ne 0 ]; then
            echo "ERROR: failed to update beta key."
        fi
        set -e
        ;;
    *)
        /opt/makemkv/bin/makemkv-set-key "$MAKEMKV_KEY" /config/settings.conf
        ;;
esac

# Take ownership of the output directory.
take-ownership --not-recursive --skip-if-writable /output

# vim:ft=sh:ts=4:sw=4:et:sts=4
