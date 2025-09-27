#!/bin/bash

# Gitpod Keep-Alive Script
# This script prevents Gitpod from going idle using multiple methods

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting aggressive keep-alive script..."

# Create a keep-alive file
KEEPALIVE_FILE="/tmp/gitpod-keepalive"

while true; do
    # Method 1: File activity
    echo "$(date)" > "$KEEPALIVE_FILE"
    touch /tmp/keepalive-$(date +%s) 2>/dev/null || true
    
    # Method 2: Network activity (ping localhost)
    ping -c 1 127.0.0.1 >/dev/null 2>&1 || true
    
    # Method 3: Process activity (create temporary processes)
    (sleep 1 && echo "keepalive" >/dev/null) &
    
    # Method 4: System activity (update system time)
    date >/dev/null 2>&1
    
    # Method 5: Memory activity (allocate and free memory)
    python3 -c "import time; time.sleep(0.1)" 2>/dev/null || true
    
    # Method 6: Disk activity (create and remove temp files)
    TEMP_FILE="/tmp/keepalive-$(date +%s)-$$"
    echo "keepalive" > "$TEMP_FILE" 2>/dev/null || true
    rm -f "$TEMP_FILE" 2>/dev/null || true
    
    log "Keep-alive signal sent (multiple methods)"
    
    # Sleep for 2 minutes (120 seconds) - more frequent
    sleep 120
done
