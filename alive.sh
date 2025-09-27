#!/bin/bash

export DISPLAY=:99

if ! command -v xdotool &> /dev/null; then
    echo "xdotool not found. Installing..."
    sudo apt-get update && sudo apt-get install -y xdotool
fi

echo "Starting keep-alive script..."

while true; do
    xdotool key BackSpace
    sleep 300
done
