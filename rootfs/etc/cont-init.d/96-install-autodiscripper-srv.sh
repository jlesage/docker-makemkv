#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

MAKEMKV_CLI="env HOME=/config LD_PRELOAD=/opt/makemkv/lib/umask_wrapper.so /opt/makemkv/bin/makemkvcon"

# Clear actual services, if any.
rm -rf /etc/services.d/autodiscripper*

if [ "${AUTO_DISC_RIPPER:-0}" -eq 0 ]; then
    log "automatic disc ripper disabled."
    exit 0
fi

if [ "${MAKEMKV_OPTICAL_DRIVE_PRESENT:-0}" -eq 0 ]; then
    log "no usable optical drive available."
    exit 0
fi

if [ "${AUTO_DISC_RIPPER_PARALLEL_RIP:-0}" -eq 0 ]; then
    log "installing automatic disc ripper service..."
    mkdir /etc/services.d/autodiscripper
    cp /defaults/autodiscripper.run /etc/services.d/autodiscripper/run
else
    $MAKEMKV_CLI -r --cache=1 info disc:9999 | grep "^DRV:[0-9]\+,[1|2]," | while read DRV_INFO
    do
        DRV_ID="$(echo "$DRV_INFO" | cut -d',' -f1 | cut -d':' -f2)"
        DRV_NAME="$(echo "$DRV_INFO" | cut -d',' -f5 | tr -d '"')"

        log "installing automatic disc ripper for drive $DRV_ID ($DRV_NAME)..."
        mkdir /etc/services.d/autodiscripper-$DRV_ID
        cp /defaults/autodiscripper.run /etc/services.d/autodiscripper-$DRV_ID/run
    done
fi

# vim: set ft=sh :
