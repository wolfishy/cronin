# Whaleon WebSocket Logging System

A complete WebSocket-based logging system for whaleon with three components:

1. **WebSocket Server** - Silent receiver that stores logs in SQLite database
2. **WebSocket Client (Sender)** - Monitors whaleon logs and sends them to the server
3. **WebSocket Client (Reader)** - Displays logs in real-time from the server

## Architecture

```
┌─────────────────┐    WebSocket     ┌─────────────────┐    WebSocket     ┌─────────────────┐
│   whaleon       │ ────────────────▶│  WS Server      │ ◀────────────────│  WS Log Reader  │
│   (nohup.out)   │                  │  (SQLite DB)    │                  │  (Local Machine)│
└─────────────────┘                  └─────────────────┘                  └─────────────────┘
         │                                    │
         ▼                                    ▼
┌─────────────────┐                  ┌─────────────────┐
│  WS Client      │                  │  Silent Storage │
│  (Log Sender)   │                  │  No Console     │
└─────────────────┘                  └─────────────────┘
```

## Components

### 1. WebSocket Server (`websocket_server.py`)

- 🔇 **Silent receiver** - No console output for received messages
- 💾 **Upstash Redis storage** - Stores all logs in Redis with 7-day expiration
- 🔄 **Auto-acknowledgment** - Sends confirmation back to clients
- 🛡️ **Error handling** - Graceful error responses
- 📊 **Statistics tracking** - Per-source log counts and message types

### 2. WebSocket Client - Sender (`websocket_client.py`)

- 🐋 **Monitors whaleon** - Watches `nohup.out` for changes
- 📡 **Sends last 5 lines** - Only when logs actually change
- 🔄 **Auto-reconnection** - Exponential backoff on connection loss
- 💓 **Heartbeat** - Keeps connection alive every 30 seconds
- 📝 **Smart log management** - Overrides `nohup.out` with only last 5 lines

### 3. WebSocket Client - Reader (`websocket_log_reader.py`)

- 📱 **Real-time display** - Shows logs as they arrive
- 🎨 **Color-coded output** - Different colors for log types
- 🔌 **Auto-reconnection** - Handles server disconnections
- 📊 **Message counter** - Tracks received messages

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Start the WebSocket Server

```bash
# Default: localhost:8080
python3 websocket_server.py

# Custom host/port
python3 websocket_server.py 0.0.0.0 9000
```

### 3. Start whaleon with Log Sender

```bash
# Using startup script (recommended)
./start_whaleon_with_logs.sh ws://localhost:8080

# Or manually
nohup ./whaleon start --headless --max-threads 2 --max-difficulty extra_large_2 --node-id 36381824 > nohup.out 2>&1 &
python3 websocket_client.py ws://localhost:8080
```

### 4. Read Logs on Local Machine

```bash
# Connect to server and display logs
python3 websocket_log_reader.py ws://your-server.com:8080
```

## Usage Examples

### Basic Setup (All on same machine)

```bash
# Terminal 1: Start server (uses embedded Redis credentials)
python3 websocket_server.py

# Or with custom Redis credentials:
python3 websocket_server.py --redis-url "https://your-redis.upstash.io" --redis-token "your-token"

# Terminal 2: Start whaleon + sender
./start_whaleon_with_logs.sh

# Terminal 3: Read logs
python3 websocket_log_reader.py
```

### Remote Setup (Server on different machine)

```bash
# On server machine (192.168.1.100):
python3 websocket_server.py 0.0.0.0 8080

# On whaleon machine:
./start_whaleon_with_logs.sh ws://192.168.1.100:8080

# On your local machine:
python3 websocket_log_reader.py ws://192.168.1.100:8080
```

## Message Format

### Sent by Log Sender

```json
{
  "timestamp": "2024-01-01T12:00:00.000000",
  "message": ["StateChange [2024-01-01 12:00:00] Task completed", "Success [2024-01-01 12:00:01] Got task NX-01K647RGACYW27NCFXK4NR8HX9"],
  "source": "whaleon-36381824",
  "type": "log",
  "line_count": 2
}
```

### Server Response

```json
{
  "timestamp": "2024-01-01T12:00:00.000000",
  "status": "received",
  "message_id": 42
}
```

## Log Reader Output

```
🐋 Whaleon Log Reader
==================================================
🔌 Connecting to WebSocket server: ws://localhost:8080
✅ Connected to WebSocket server
📡 Listening for whaleon logs...
Press Ctrl+C to stop
--------------------------------------------------
[0001] 12:00:00 [LOG] whaleon (36381824) (2 lines):
  1: StateChange [2024-01-01 12:00:00] Task completed
  2: Success [2024-01-01 12:00:01] Got task NX-01K647RGACYW27NCFXK4NR8HX9

[0002] 12:00:30 [HEARTBEAT] whaleon (36381824): 💓 Heartbeat from whaleon client

[0003] 12:01:00 [STATUS] whaleon (36381824): 🚀 Whaleon log sender connected and ready
```

## Redis Storage

The server stores logs in Upstash Redis with the following structure:

### Log Storage

- **Individual logs**: `log:{timestamp}:{source}:{counter}` (Hash)
- **Recent logs per source**: `recent_logs:{source}` (List, max 100 entries)
- **Global recent logs**: `recent_logs:global` (List, max 1000 entries)
- **Source statistics**: `stats:{source}` (Hash with counts and last seen)

### Data Structure

```json
{
  "timestamp": "2024-01-01T12:00:00.000000",
  "source": "whaleon-36381824",
  "message_type": "log",
  "message_content": "StateChange [2024-01-01 12:00:00] Task completed",
  "line_count": 1,
  "created_at": "2024-01-01T12:00:00.000000"
}
```

### Expiration

- All log entries expire after **7 days**
- Automatic cleanup prevents storage bloat

## Configuration

### WebSocket Server

- **Default host**: `localhost`
- **Default port**: `8080`
- **Storage**: Upstash Redis (embedded credentials)
- **Silent mode**: No console output for received messages
- **Log expiration**: 7 days automatic cleanup

### Log Sender Client

- **Log file**: `nohup.out`
- **Lines sent**: Last 5 non-empty lines
- **Update interval**: 2 seconds (only when logs change)
- **Heartbeat**: Every 30 seconds
- **Max reconnects**: 10 attempts with exponential backoff

### Log Reader Client

- **Auto-reconnect**: Yes, with exponential backoff
- **Color coding**: Green (logs), Yellow (status), Cyan (heartbeat), Red (errors)
- **Message counter**: Shows total received messages

## Files

- `websocket_server.py` - Silent WebSocket server with Upstash Redis storage
- `websocket_client.py` - Log sender client (monitors whaleon)
- `websocket_log_reader.py` - Log reader client (displays logs)
- `redis_log_viewer.py` - View stored logs from Redis
- `start_whaleon_with_logs.sh` - Startup script for whaleon + sender
- `requirements.txt` - Python dependencies

## Troubleshooting

### Server Issues

- Check if port is available: `netstat -tulpn | grep :8080`
- Verify Redis connection: Server will show connection status on startup
- Check firewall settings for remote connections
- Ensure Upstash Redis credentials are correct

### Sender Issues

- Ensure whaleon is running: `ps aux | grep whaleon`
- Check `nohup.out` exists and has content
- Verify WebSocket server is accessible

### Reader Issues

- Test server connection: `telnet server-ip 8080`
- Check WebSocket URL format
- Verify server is running and accessible

## Advanced Usage

### View Stored Logs

```bash
# View recent logs from all sources
python3 redis_log_viewer.py

# View logs from specific source
python3 redis_log_viewer.py --source whaleon-36381824

# Show statistics
python3 redis_log_viewer.py --stats

# View more logs
python3 redis_log_viewer.py --limit 100
```

### Query Redis Directly

```python
from upstash_redis import Redis

redis = Redis(url="https://apt-robin-12793.upstash.io",
              token="ATH5AAIncDIxNmUwOWNlY2VhYTE0ZTJlOWQxODY1NzFiOGMyYjU2NXAyMTI3OTM")

# Get recent logs
log_ids = redis.lrange("recent_logs:global", 0, 9)
for log_id in log_ids:
    log_data = redis.hgetall(log_id)
    print(f"Log: {log_data}")
```

### Custom Log Processing

You can extend the server to process logs differently or add custom handlers for specific message types.

## Security Notes

- The server accepts connections from any IP by default
- Consider adding authentication for production use
- Use WSS (WebSocket Secure) for encrypted connections
- Implement rate limiting for high-volume scenarios
