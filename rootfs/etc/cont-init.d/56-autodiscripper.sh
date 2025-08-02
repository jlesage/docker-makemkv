#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Check if the automatic disc ripper is enabled.
if is-bool-val-false "${AUTO_DISC_RIPPER:-0}"; then
    exit 0
fi

# NOTE: makemkvcon is used here only to list devices. As a workaround for a bug
#       where makemkvcon clears the `settings.conf` configuration file when it
#       contains an expired beta key, use a copy of the user settings in a
#       separate home directory.
#       See https://github.com/jlesage/docker-makemkv/issues/172
TMP_HOME="$(mktemp -d)"
cp /config/settings.conf "$TMP_HOME"
ln -s "$TMP_HOME" "$TMP_HOME"/.MakeMKV

# Remove settings that are not needed to list drives.
sed -i '/^app_ShowDebug[= ]/d' "$TMP_HOME"/settings.conf
sed -i '/^app_UpdateEnable[= ]/d' "$TMP_HOME"/settings.conf
echo 'app_UpdateEnable = "0"' >> "$TMP_HOME"/settings.conf

MAKEMKV_CLI="env HOME=$TMP_HOME LD_PRELOAD=/opt/makemkv/lib/libwrapper.so /opt/makemkv/bin/makemkvcon"

# Save drives information as seen by MakeMKV.
echo "getting supported drives..."
$MAKEMKV_CLI -r --cache=1 --noscan info disc:9999 > "$TMP_HOME"/makemkvcon.output

# Extract found drives.
grep "^DRV:[0-9]\+,[0|1|2]," "$TMP_HOME"/makemkvcon.output > /tmp/.makemkv_supported_drives || true
if [ -z "$(cat /tmp/.makemkv_supported_drives)" ]; then
   echo "WARNING: no supported drives found"
   echo "         automatic disc ripper will be disabled"
fi

# Display the raw output if debug is enabled.
is-bool-val-false "${CONTAINER_DEBUG:-0}" || sed 's/^/makemkvcon: /' < "$TMP_HOME"/makemkvcon.output

rm -rf "$TMP_HOME"

# vim:ft=sh:ts=4:sw=4:et:sts=4
