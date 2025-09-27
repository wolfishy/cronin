#!/usr/bin/env python3
"""
Configuration for Nexus Client-Sender
"""

import os

# VPS Server Configuration
# Replace 'your-vps-ip' with your actual VPS IP address
VPS_IP = os.environ.get("VPS_IP", "143.198.192.51")
VPS_WS_PORT = os.environ.get("VPS_WS_PORT", "6969")

# WebSocket server URL
WS_SERVER_URL = f"ws://{VPS_IP}:{VPS_WS_PORT}"

# Log file configuration
LOG_FILE = os.environ.get("LOG_FILE", "whaleon.log")

# Whaleon process configuration
WHALEON_NODE_ID = os.environ.get("WHALEON_NODE_ID", "default-node")

# Reconnection settings
RECONNECT_INTERVAL = 5  # seconds
MAX_RECONNECT_ATTEMPTS = -1  # -1 for infinite attempts
