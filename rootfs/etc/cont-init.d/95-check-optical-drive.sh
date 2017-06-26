#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

echo "Looking for usable optical drives..."

DRIVES_INFO="$(mktemp)"
/opt/makemkv/bin/makemkvcon -r --cache=1 info disc:9999 | grep "^DRV:" > "$DRIVES_INFO" 2>&1

while read -r DRV; do
    DRV_ID="$(echo "$DRV" | cut -d',' -f1 | cut -d':' -f2)"
    DRV_DEV="$(echo "$DRV" | cut -d',' -f7 | tr -d '"')"
    if [ "${DRV_DEV:-UNSET}" != "UNSET" ]; then
        DRV_GRP="$(stat -c "%g" "$DRV_DEV")"
        echo "Found drive $DRV_ID ($DRV_DEV), group $DRV_GRP."
        GRPS="${GRPS:- } $DRV_GRP"
    fi
done < "$DRIVES_INFO"
rm "$DRIVES_INFO"

if [ "${DRV_GRP:-UNSET}" = "UNSET" ]; then
    echo "No usable optical drive found."
else
    # Save as comma separated list of supplementary group IDs.
    echo "$GRPS" | tr ' ' '\n' | grep -v '^$' | sort -nub | tr '\n' ',' | sed 's/.$//' > /var/run/s6/container_environment/SUP_GROUP_IDS
    # Save an indication that at least one optical drive has been found.
    echo "1" > /var/run/s6/container_environment/MAKEMKV_OPTICAL_DRIVE_PRESENT
fi

# vim: set ft=sh :
