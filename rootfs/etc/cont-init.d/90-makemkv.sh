#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

# Generate machine id
if [ ! -f /etc/machine-id ]; then
    log "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id
fi

mkdir -p "$XDG_CONFIG_HOME"

# Upgrade previous installations.
[ ! -f /config/QtProject.conf ] || mv -v /config/QtProject.conf "$XDG_CONFIG_HOME/"
if [ -f /config/settings.conf ]; then
    if ! grep -w app_ccextractor /config/settings.conf; then
        echo 'app_ccextractor = "/usr/bin/ccextractor"' >> /config/settings.conf
    fi
fi

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

# Make sure the data directory is correctly set.
sed -i 's|app_DataDir = .*|app_DataDir = "/config/data"|' /config/settings.conf

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

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# Take ownership of the output directory.
if ! chown $USER_ID:$GROUP_ID /output; then
    # Failed to take ownership of /output.  This could happen when,
    # for example, the folder is mapped to a network share.
    # Continue if we have write permission, else fail.
    TMPFILE="$(s6-setuidgid $USER_ID:$GROUP_ID mktemp /output/.test_XXXXXX 2>/dev/null)"
    if [ $? -eq 0 ]; then
        # Success, we were able to write file.
        s6-setuidgid $USER_ID:$GROUP_ID rm "$TMPFILE"
    else
        log "ERROR: Failed to take ownership and no write permission on /output."
        exit 1
    fi
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
