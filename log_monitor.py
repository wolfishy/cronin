#!/usr/bin/env python3
"""
Simple and Reliable Log Monitor
Uses subprocess to tail the nohup.out file and processes each line
"""

import asyncio
import subprocess
import sys
from datetime import datetime
import socketio


class LogMonitor:
    def __init__(self, node_id: str, server_url: str):
        self.node_id = node_id
        self.server_url = server_url
        self.sio = socketio.AsyncClient()
        self.connected = False
        self.setup_handlers()

    def setup_handlers(self):
        @self.sio.event
        async def connect():
            print(f"Connected to {self.server_url}")
            self.connected = True

        @self.sio.event
        async def disconnect():
            print("Disconnected from server")
            self.connected = False

    async def connect_socketio(self):
        """Connect to Socket.IO server."""
        try:
            await self.sio.connect(self.server_url)
            await self.sio.wait()
        except Exception as e:
            print(f"Socket.IO connection failed: {e}")

    async def send_log(self, message: str):
        """Send log to Socket.IO server."""
        if self.connected:
            try:
                data = {
                    "node_id": self.node_id,
                    "message": message,
                    "time": datetime.now().isoformat(),
                }
                await self.sio.emit("log_message", data)
            except Exception as e:
                print(f"Error sending log: {e}")

    def save_latest_output(self, message: str):
        """Save latest output to file."""
        try:
            with open("/tmp/latest_whaleon_output.txt", "w", encoding="utf-8") as f:
                f.write(f"{datetime.now().isoformat()}: {message}\n")
        except Exception as e:
            print(f"Error saving output: {e}")

    async def monitor_logs(self):
        """Monitor logs using tail -f subprocess."""
        try:
            process = subprocess.Popen(
                ["tail", "-f", "nohup.out"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True,
            )

            print("Monitoring nohup.out with tail -f...")

            for line in iter(process.stdout.readline, ""):
                if line.strip():
                    self.save_latest_output(line.strip())
                    await self.send_log(line.strip())

        except Exception as e:
            print(f"Error monitoring logs: {e}")
        finally:
            if process:
                process.terminate()


async def main():
    if len(sys.argv) != 2:
        print("Usage: python3 log_monitor.py <node_id>")
        sys.exit(1)

    node_id = sys.argv[1]
    server_url = "http://143.198.192.51:6969"

    monitor = LogMonitor(node_id, server_url)

    asyncio.create_task(monitor.connect_socketio())

    await asyncio.sleep(2)
    await monitor.monitor_logs()


if __name__ == "__main__":
    asyncio.run(main())
