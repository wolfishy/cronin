FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install GNOME core, Chrome, and noVNC dependencies
RUN apt-get update && apt-get install -y \
    gnome-session gnome-terminal \
    x11vnc xvfb \
    novnc websockify \
    wget gnupg2 \
    dbus-x11 \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Expose noVNC port
EXPOSE 8080

# Start GNOME session with Chrome via noVNC
CMD export DISPLAY=:0 && \
    Xvfb :0 -screen 0 1920x1080x24 & \
    dbus-run-session -- gnome-session & \
    x11vnc -display :0 -nopw -forever -shared -rfbport 5900 & \
    websockify --web=/usr/share/novnc/ 8080 localhost:5900
