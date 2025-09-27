#!/bin/bash

# Gitpod Keep-Alive Script
# This script prevents Gitpod from going idle by simulating user activity

export DISPLAY=:99

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if xdotool is installed
if ! command -v xdotool &> /dev/null; then
    log "xdotool not found. Installing..."
    sudo apt-get update && sudo apt-get install -y xdotool
fi

# Wait for VNC server to be ready
log "Waiting for VNC server to be ready..."
for i in {1..30}; do
    if xdotool getactivewindow &>/dev/null; then
        log "VNC server is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        log "Warning: VNC server may not be ready, but continuing anyway..."
    fi
    sleep 2
done

log "Starting keep-alive script..."

while true; do
    # Try to send a harmless key press (Shift key doesn't affect anything)
    if xdotool key shift &>/dev/null; then
        log "Signal sent successfully"
    else
        log "Warning: Failed to send signal"
    fi
    
    # Sleep for 4 minutes (240 seconds)
    sleep 240
done
