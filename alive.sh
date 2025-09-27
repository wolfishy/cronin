#!/bin/bash

# Gitpod Keep-Alive Script
# This script prevents Gitpod from going idle using xdotool + fallback methods

export DISPLAY=:99

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting hybrid keep-alive script..."

# Check if xdotool is available and working
XDOTOOL_AVAILABLE=false
if command -v xdotool &> /dev/null; then
    # Test if xdotool can work with the display (skip getactivewindow test)
    if timeout 5 xdotool key space &>/dev/null; then
        XDOTOOL_AVAILABLE=true
        log "xdotool is available and working"
    else
        log "xdotool available but display not ready, will retry"
    fi
else
    log "xdotool not found, using fallback methods only"
fi

# Create a keep-alive file
KEEPALIVE_FILE="/tmp/gitpod-keepalive"

while true; do
    # Primary Method: xdotool (if available and working)
    if [ "$XDOTOOL_AVAILABLE" = true ]; then
        if xdotool key space &>/dev/null; then
            log "Keep-alive signal sent (xdotool - space key)"
        else
            log "xdotool failed, switching to fallback methods"
            XDOTOOL_AVAILABLE=false
        fi
    fi
    
    # Fallback Method: Simple file activity (if xdotool fails)
    if [ "$XDOTOOL_AVAILABLE" = false ]; then
        echo "$(date)" > "$KEEPALIVE_FILE"
        log "Keep-alive signal sent (file activity fallback)"
        
        # Try to re-enable xdotool
        if command -v xdotool &> /dev/null; then
            if timeout 5 xdotool key space &>/dev/null; then
                XDOTOOL_AVAILABLE=true
                log "xdotool is now working, switching back"
            fi
        fi
    fi
    
    # Sleep for 2 minutes (120 seconds)
    sleep 120
done
