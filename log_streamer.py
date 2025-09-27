#!/usr/bin/env python3
"""
Nexus Log Streamer
Streams logs from whaleon process to WebSocket server.
"""

import asyncio
import json
import logging
import os
import signal
import sys
from datetime import datetime
from typing import Optional

import socketio

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# Import configuration and parser
from config import (
    WS_SERVER_URL,
    RECONNECT_INTERVAL,
    WHALEON_NODE_ID,
)

from whaleon_parser import WhaleonLogParser

# Nohup output file to monitor
NOHUP_OUTPUT_FILE = "nohup.out"

# Global variables
sio: Optional[socketio.AsyncClient] = None
reconnect_task: Optional[asyncio.Task] = None


class LogStreamer:
    """Handles log streaming to Socket.IO server."""

    def __init__(self):
        self.sio = socketio.AsyncClient()
        self.reconnect_interval = RECONNECT_INTERVAL
        self.connected = False
        self._setup_handlers()

    def _setup_handlers(self):
        """Set up Socket.IO event handlers."""

        @self.sio.event
        async def connect():
            logger.info("Socket.IO connected successfully")
            self.connected = True
            await self.send_connection_message()

        @self.sio.event
        async def disconnect():
            logger.info("Socket.IO disconnected")
            self.connected = False

        @self.sio.event
        async def connect_error(data):
            logger.error(f"Socket.IO connection error: {data}")
            self.connected = False

    async def connect_socketio(self) -> None:
        """Connect to Socket.IO server with auto-reconnection."""
        global sio

        while True:
            try:
                logger.info(f"Connecting to Socket.IO server: {WS_SERVER_URL}")
                await self.sio.connect(WS_SERVER_URL)
                sio = self.sio

                # Wait for connection to be established
                await self.sio.wait()

            except Exception as e:
                logger.error(f"Socket.IO connection error: {e}")
                self.connected = False
                logger.info(f"Reconnecting in {self.reconnect_interval} seconds...")
                await asyncio.sleep(self.reconnect_interval)

    async def send_connection_message(self) -> None:
        """Send initial connection message with node ID."""
        if not self.connected:
            return

        message = {
            "type": "log-streamer",
            "message": "Log streamer connected",
            "timestamp": datetime.now().isoformat(),
            "source": "client-sender",
            "node_id": WHALEON_NODE_ID,
        }

        try:
            await self.send_message(message)
            logger.info(f"Sent connection message for node: {WHALEON_NODE_ID}")
        except Exception as e:
            logger.error(f"Error sending connection message: {e}")

    async def send_message(self, message: dict) -> None:
        """Send message to Socket.IO server."""
        if self.connected and self.sio:
            try:
                await self.sio.emit("log_message", message)
            except Exception as e:
                logger.error(f"Error sending message: {e}")
                raise
        else:
            logger.warning("Socket.IO not connected, message queued")

    async def send_latest_message(self, log_data: str) -> None:
        """Send the latest log message to Socket.IO server."""
        message = {
            "node_id": WHALEON_NODE_ID,
            "message": log_data,
            "time": datetime.now().isoformat(),
        }

        if self.connected and self.sio:
            try:
                await self.sio.emit("log_message", message)
                logger.debug(f"Sent latest message: {log_data[:50]}...")
            except Exception as e:
                logger.error(f"Error sending latest message: {e}")
                raise
        else:
            logger.warning("Socket.IO not connected, message queued")

    async def send_log(self, log_data: str) -> None:
        """Send log data to Socket.IO server immediately."""
        try:
            # Send the latest message immediately
            await self.send_latest_message(log_data)
        except Exception as e:
            logger.error(f"Error sending log: {e}")


# ProcessMonitor class removed - we now use NohupOutputMonitor instead
# The whaleon process is started by .gitpod.yml and we monitor its output files


class NohupOutputMonitor:
    """Monitors nohup output files for changes."""

    def __init__(self, log_streamer: LogStreamer):
        self.log_streamer = log_streamer
        self.last_positions = {}  # Track last position for each file

    async def send_existing_content(self, file_path: str) -> None:
        """Send existing content from a file (for initial catch-up)."""
        try:
            if not os.path.exists(file_path):
                return

            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()

            if content.strip():
                logger.info(
                    f"Sending existing content from {file_path} ({len(content)} chars)"
                )
                for line in content.splitlines():
                    if line.strip():
                        await self.log_streamer.send_log(line.strip())

        except Exception as e:
            logger.error(f"Error sending existing content from {file_path}: {e}")

    async def monitor_nohup_output(self) -> None:
        """Monitor nohup output file for new entries."""
        # Monitor the nohup output file
        file_to_monitor = NOHUP_OUTPUT_FILE

        # Check if nohup output file exists
        if not os.path.exists(file_to_monitor):
            logger.warning(f"No nohup output file found: {file_to_monitor}")
            return

        # Initialize monitoring
        self.last_positions[file_to_monitor] = os.path.getsize(file_to_monitor)
        logger.info(f"Will monitor: {file_to_monitor}")

        # Send existing content for initial catch-up
        await self.send_existing_content(file_to_monitor)

        logger.info("Starting nohup output monitoring")

        try:
            while True:
                try:
                    if not os.path.exists(file_to_monitor):
                        logger.warning(f"Output file disappeared: {file_to_monitor}")
                        await asyncio.sleep(5)
                        continue

                    current_size = os.path.getsize(file_to_monitor)
                    last_position = self.last_positions.get(file_to_monitor, 0)

                    if current_size > last_position:
                        # Read new content
                        with open(
                            file_to_monitor, "r", encoding="utf-8", errors="ignore"
                        ) as f:
                            f.seek(last_position)
                            new_content = f.read()

                        # Get only the latest line from new content
                        new_lines = [
                            line.strip()
                            for line in new_content.splitlines()
                            if line.strip()
                        ]
                        if new_lines:
                            # Send only the latest line
                            latest_line = new_lines[-1]
                            await self.log_streamer.send_log(latest_line)
                            logger.debug(
                                f"Sent latest line from {file_to_monitor}: {latest_line[:50]}..."
                            )

                        self.last_positions[file_to_monitor] = current_size

                    await asyncio.sleep(1)  # Check every second

                except Exception as e:
                    logger.error(f"Error monitoring nohup output: {e}")
                    await asyncio.sleep(5)  # Wait longer on error

        except Exception as e:
            logger.error(f"Nohup output monitoring failed: {e}")


async def main():
    """Main function."""
    global reconnect_task

    logger.info("Starting Nexus Log Streamer")
    logger.info(f"Socket.IO Server: {WS_SERVER_URL}")
    logger.info(f"Node ID: {WHALEON_NODE_ID}")
    logger.info(f"Monitoring nohup output file: {NOHUP_OUTPUT_FILE}")

    # Create log streamer
    log_streamer = LogStreamer()

    # Start Socket.IO connection
    reconnect_task = asyncio.create_task(log_streamer.connect_socketio())

    # Wait a bit for Socket.IO connection
    await asyncio.sleep(2)

    # Start monitoring nohup output files
    nohup_monitor = NohupOutputMonitor(log_streamer)
    monitor_task = asyncio.create_task(nohup_monitor.monitor_nohup_output())

    try:
        # Wait for tasks
        await asyncio.gather(reconnect_task, monitor_task)
    except Exception as e:
        logger.error(f"Main loop error: {e}")


def signal_handler(signum, frame):
    """Handle shutdown signals."""
    logger.info("Received shutdown signal")
    # Note: We don't manage the whaleon process directly - it's started by .gitpod.yml with nohup
    sys.exit(0)


if __name__ == "__main__":
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Log streamer stopped by user")
    except Exception as e:
        logger.error(f"Log streamer error: {e}")
        sys.exit(1)
