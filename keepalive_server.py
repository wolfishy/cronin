#!/usr/bin/env python3
"""
Simple HTTP keep-alive server
This creates a minimal HTTP server that responds to keep-alive requests
"""

import http.server
import socketserver
import threading
import time
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="[%(asctime)s] %(levelname)s: %(message)s"
)
logger = logging.getLogger(__name__)


class KeepAliveHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/keepalive":
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK")
            logger.info("Keep-alive request received")
        else:
            self.send_response(404)
            self.end_headers()


def start_keepalive_server():
    """Start the keep-alive HTTP server on port 8081"""
    try:
        with socketserver.TCPServer(("", 8081), KeepAliveHandler) as httpd:
            logger.info("Keep-alive server started on port 8081")
            httpd.serve_forever()
    except Exception as e:
        logger.error(f"Keep-alive server error: {e}")


def keepalive_client():
    """Client that pings the keep-alive server"""
    import urllib.request
    import urllib.error

    while True:
        try:
            urllib.request.urlopen("http://localhost:8081/keepalive", timeout=5)
            logger.info("Keep-alive ping sent")
        except Exception as e:
            logger.warning(f"Keep-alive ping failed: {e}")

        time.sleep(60)  # Ping every minute


if __name__ == "__main__":
    # Start server in background thread
    server_thread = threading.Thread(target=start_keepalive_server, daemon=True)
    server_thread.start()

    # Start client in main thread
    keepalive_client()
