#!/bin/bash

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting hybrid keep-alive script..."
log "DISPLAY is set to: $DISPLAY"

# Wait for X11/VNC to initialize
sleep 30
log "Waited 30 seconds for X11/VNC to initialize"

# Check if xdotool is available and working
XDOTOOL_AVAILABLE=false
if command -v xdotool &> /dev/null; then
    log "xdotool is installed"
    # Test xdotool with XFCE window names or root window
    if timeout 5 xdotool search --name "xfce4-panel|Desktop|wrapper-2.0" key space 2>&1 || timeout 5 xdotool key --window 0 space 2>&1; then
        XDOTOOL_AVAILABLE=true
        log "xdotool is available and working"
    else
        log "xdotool test failed, will retry"
    fi
else
    log "xdotool not found, using fallback methods only"
fi

# Create a keep-alive file
KEEPALIVE_FILE="/tmp/gitpod-keepalive"

while true; do
    # Primary Method: xdotool (if available and working)
    if [ "$XDOTOOL_AVAILABLE" = true ]; then
        if xdotool search --name "xfce4-panel|Desktop|wrapper-2.0" key space 2>&1; then
            log "Keep-alive signal sent (xdotool - space key to xfce4-panel/Desktop/wrapper-2.0)"
        elif xdotool key --window 0 space 2>&1; then
            log "Keep-alive signal sent (xdotool - space key to root window)"
        else
            log "xdotool failed, switching to fallback methods"
            XDOTOOL_AVAILABLE=false
        fi
    fi
    
    # Fallback Method: File activity + terminal output
    if [ "$XDOTOOL_AVAILABLE" = false ]; then
        echo "$(date)" > "$KEEPALIVE_FILE"
        echo "keepalive $(date)"
        log "Keep-alive signal sent (file activity + terminal output fallback)"
        
        # Try to re-enable xdotool
        if command -v xdotool &> /dev/null; then
            if timeout 5 xdotool search --name "xfce4-panel|Desktop|wrapper-2.0" key space &>/dev/null || timeout 5 xdotool key --window 0 space &>/dev/null; then
                XDOTOOL_AVAILABLE=true
                log "xdotool is now working, switching back"
            fi
        fi
    fi
    
    # Sleep for 1 minute (60 seconds) for frequent activity
    sleep 60
done