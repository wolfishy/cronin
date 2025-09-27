#!/bin/bash
set -euo pipefail

while true; do
  # simulate harmless keypress to register activity
  xdotool key shift
  sleep 300   # every 5 minutes
done
