#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

log "looking for usable optical drives..."

DRIVES_INFO="$(mktemp)"
lsscsi -g -k | grep -w "cd/dvd" | tr -s ' ' > "$DRIVES_INFO"

while read -r DRV; do
    SR_DEV="$(echo "$DRV" | rev | cut -d' ' -f2 | rev)"
    SG_DEV="$(echo "$DRV" | rev | cut -d' ' -f1 | rev)"

    if [ -e "$SG_DEV" ] && [ -e "$SR_DEV" ]; then
        # Save the associated group.
        DRV_GRP="$(stat -c "%g" "$SR_DEV")"
        log "found optical drive [$SR_DEV, $SG_DEV], group $DRV_GRP."
        GRPS="${GRPS:- } $DRV_GRP"
    elif [ -e "$SG_DEV" ]; then
        # Save the associated group.
        DRV_GRP="$(stat -c "%g" "$SG_DEV")"
        log "found optical drive [$SR_DEV, $SG_DEV], group $DRV_GRP."
        log "WARNING: for best perfomance, the host device $SR_DEV needs to be exposed to the container."
        GRPS="${GRPS:- } $DRV_GRP"
    else
        log "found optical drive [$SR_DEV, $SG_DEV], but it is not usable because:"
        [ -e "$SR_DEV" ] || log "  --> the host device $SR_DEV is not exposed to the container."
        [ -e "$SG_DEV" ] || log "  --> the host device $SG_DEV is not exposed to the container."
    fi
done < "$DRIVES_INFO"
rm "$DRIVES_INFO"

if [ "${DRV_GRP:-UNSET}" = "UNSET" ]; then
    log "no usable optical drive found."
else
    # Save as comma separated list of supplementary group IDs.
    echo "$GRPS" | tr ' ' '\n' | grep -v '^$' | sort -nub | tr '\n' ',' | sed 's/.$//' > /var/run/s6/container_environment/SUP_GROUP_IDS
    # Save an indication that at least one optical drive has been found.
    echo "1" > /var/run/s6/container_environment/MAKEMKV_OPTICAL_DRIVE_PRESENT
fi

# vim: set ft=sh :
