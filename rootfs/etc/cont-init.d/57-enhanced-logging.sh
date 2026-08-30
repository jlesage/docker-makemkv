#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Check if Apprise notifications are configured
APPRISE_CONFIGURED=false
if [ -f /config/apprise.yml ]; then
    echo "Apprise configuration detected - notifications will be sent."
    APPRISE_CONFIGURED=true
fi

# Enable enhanced logging if requested OR if Apprise is configured
# (notifications require debug logging to work)
if is-bool-val-true "${ENABLE_DOCKER_LOGGING:-0}" || is-bool-val-true "$APPRISE_CONFIGURED"; then
    if is-bool-val-true "$APPRISE_CONFIGURED"; then
        echo "Enabling debug logging (required for notifications)..."
    else
        echo "Enabling enhanced Docker logging..."
    fi
    
    # Ensure debug logging is enabled
    if [ -f /config/settings.conf ]; then
        # Ensure app_ShowDebug is set to "1"
        if grep -q "^[ \t]*app_ShowDebug[ \t]*=" /config/settings.conf; then
            sed -i 's|^[ \t]*app_ShowDebug[ \t]*=.*|app_ShowDebug = "1"|' /config/settings.conf
        else
            echo 'app_ShowDebug = "1"' >> /config/settings.conf
        fi
        
        echo "Debug logging enabled."
    fi
else
    echo "Enhanced Docker logging disabled (ENABLE_DOCKER_LOGGING=0)."
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4