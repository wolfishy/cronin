#!/bin/bash

# Aggressive Gitpod Keep-Alive Script with Keyboard Input
# This script prevents Gitpod from going idle using keyboard input + multiple methods

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting aggressive keep-alive script with keyboard input..."

# Set up display for xdotool
export DISPLAY=:0

# Create multiple keep-alive files
KEEPALIVE_FILE="/tmp/gitpod-keepalive"
TERMINAL_ACTIVITY="/tmp/terminal-activity"
PROCESS_ACTIVITY="/tmp/process-activity"

# Check if xdotool is available
XDOTOOL_AVAILABLE=false
if command -v xdotool &> /dev/null; then
    XDOTOOL_AVAILABLE=true
    log "xdotool is available for keyboard input"
else
    log "xdotool not available, using printf for keyboard simulation"
fi

while true; do
    # Method 1: Real keyboard input (most important for Gitpod)
    echo "KEEPALIVE: $(date)" | tee -a "$TERMINAL_ACTIVITY"
    printf "\033[2J\033[H"  # Clear screen and move cursor to top
    
    # Method 2: Real keyboard input using xdotool or printf
    if [ "$XDOTOOL_AVAILABLE" = true ]; then
        # Try xdotool for real keyboard input
        if xdotool key space 2>/dev/null; then
            log "Real keyboard input sent (xdotool space key)"
        elif xdotool key Return 2>/dev/null; then
            log "Real keyboard input sent (xdotool Return key)"
        else
            log "xdotool failed, falling back to printf"
            printf "\n"  # Newline (Enter key)
            printf "\t"  # Tab key
            printf " "   # Space key
        fi
    else
        # Fallback to printf keyboard simulation
        printf "\n"  # Newline (Enter key)
        printf "\t"  # Tab key
        printf " "   # Space key
        log "Keyboard simulation sent (printf)"
    fi
    
    # Method 3: File system activity
    echo "$(date)" > "$KEEPALIVE_FILE"
    touch "/tmp/keepalive-$(date +%s)-$$" 2>/dev/null || true
    
    # Method 4: Process activity
    echo "$$ $(date)" > "$PROCESS_ACTIVITY"
    (sleep 1 && echo "child-$$ $(date)" >> "$PROCESS_ACTIVITY") &
    
    # Method 5: System activity
    ps aux | head -5 >/dev/null 2>&1
    date >/dev/null 2>&1
    
    # Method 6: Memory activity
    python3 -c "import time; time.sleep(0.1)" 2>/dev/null || true
    
    # Method 7: Disk activity
    df -h >/dev/null 2>&1
    ls -la /tmp >/dev/null 2>&1
    
    # Method 8: Environment activity
    env | wc -l >/dev/null 2>&1
    
    log "Keep-alive signal sent (8 methods including keyboard input)"
    
    # Sleep for 30 seconds - very frequent
    sleep 30
done