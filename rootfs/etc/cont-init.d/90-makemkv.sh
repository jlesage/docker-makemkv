#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id
echo "Generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

mkdir -p "$XDG_CONFIG_HOME"

# Upgrade previous installations.
[ ! -f /config/QtProject.conf ] || mv -v /config/QtProject.conf "$XDG_CONFIG_HOME/"

# If config folder empty, copy all XML profiles so they can be easily
# copied and edited.
if [ ! -d /config/data ]; then
    mkdir /config/data
    find /opt/makemkv/share/MakeMKV/ \
        -name "*.xml" \
        -execdir cp {} /config/data/{}.example \;    
fi

# Copy default config if needed.
[ -f /config/settings.conf ] || cp -v /defaults/settings.conf /config/
[ -f "$XDG_CONFIG_HOME/QtProject.conf" ] || cp -v /defaults/QtProject.conf "$XDG_CONFIG_HOME/"

# Create link for MakeMKV config directory.
# The only configuration location MakeMKV looks for seems to be
# "$HOME/.MakeMKV".
if [ ! -e /config/.MakeMKV ]; then
    ln -s /config /config/.MakeMKV
fi

# Make sure the data directory exists.
mkdir -p /config/data

case  "${MAKEMKV_KEY:-UNSET}" in
    UNSET)
        # Nothing to do.
        ;;
    BETA)
        echo "Checking for new beta key..."
        set +e
        /opt/makemkv/bin/makemkv-update-beta-key /config/settings.conf
        if [ "$?" -ne 0 ]; then
            echo "ERROR: Failed to update beta key."
        fi
        set -e
        ;;
    *)
        /opt/makemkv/bin/makemkv-set-key "$MAKEMKV_KEY" /config/settings.conf
        ;;
esac

# Take ownership of the config directory.
chown -R $USER_ID:$GROUP_ID /config

# Take ownership of the output directory.
chown $USER_ID:$GROUP_ID /output

# vim: set ft=sh :
