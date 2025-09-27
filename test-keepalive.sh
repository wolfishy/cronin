#!/bin/bash

# Test script to verify keep-alive mechanism
echo "Testing Gitpod keep-alive mechanism..."

export DISPLAY=:99

# Check if xdotool is available
if command -v xdotool &> /dev/null; then
    echo "✓ xdotool is installed"
else
    echo "✗ xdotool is not installed"
    exit 1
fi

# Check if VNC server is running
if pgrep -x "Xvnc" > /dev/null; then
    echo "✓ VNC server is running"
else
    echo "✗ VNC server is not running"
fi

# Test xdotool functionality
echo "Testing xdotool key press..."
if xdotool key shift &>/dev/null; then
    echo "✓ xdotool key press test successful"
else
    echo "✗ xdotool key press test failed"
fi

# Check if alive.sh is running
if pgrep -f "alive.sh" > /dev/null; then
    echo "✓ keep-alive script is running"
else
    echo "✗ keep-alive script is not running"
fi

echo "Test completed!"
