#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

echo "looking for usable optical drives..."

FOUND_USABLE_DRIVE=0

DRIVES_INFO="/tmp/.drives_info"
if [ ! -f "$DRIVES_INFO" ]; then
    lsscsi -g -k | grep -w "cd/dvd" | tr -s ' ' > "$DRIVES_INFO"
fi

while read -r DRV; do
    SR_DEV="$(echo "$DRV" | { grep -oE '/dev/sr[0-9]+' || true; } )"
    SG_DEV="$(echo "$DRV" | { grep -oE '/dev/sg[0-9]+' || true; } )"

    if [ -e "$SG_DEV" ] && [ -e "$SR_DEV" ]; then
        FOUND_USABLE_DRIVE=1
        DRV_GRP="$(stat -c "%g" "$SR_DEV")"
        echo "found optical drive [$SR_DEV, $SG_DEV], group $DRV_GRP."
    elif [ -e "$SG_DEV" ]; then
        FOUND_USABLE_DRIVE=1
        DRV_GRP="$(stat -c "%g" "$SG_DEV")"
        echo "found optical drive [$SR_DEV, $SG_DEV], group $DRV_GRP."
        echo "WARNING: for best performance, the host device $SR_DEV needs to be exposed to the container."
    else
        echo "found optical drive [$SR_DEV, $SG_DEV], but it is not usable because:"
        [ -e "$SR_DEV" ] || echo "  --> the host device $SR_DEV is not exposed to the container."
        [ -e "$SG_DEV" ] || echo "  --> the host device $SG_DEV is not exposed to the container."
    fi
done < "$DRIVES_INFO"

if [ "$FOUND_USABLE_DRIVE" -eq 0 ]; then
    echo "no usable optical drive found."
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
