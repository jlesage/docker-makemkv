#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id
echo "Generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

# If config folder empty, copy all XML profiles so they can be easily
# copied and edited.
if ! find /config -mindepth 1 -print -quit | grep -q .; then
    mkdir /config/data
    find /opt/makemkv/share/MakeMKV/ \
        -name "*.xml" \
        -execdir cp {} /config/data/{}.example \;    
fi

# Copy default config if needed.
for FILE in settings.conf QtProject.conf
do
  if [ ! -f /config/$FILE ]; then
    cp /defaults/$FILE /config/
  fi
done

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
