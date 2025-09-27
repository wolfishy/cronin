#!/bin/bash

# Nexus Services Management Script
# Manages nohup processes for whaleon and log streamer

case "$1" in
    status)
        echo "Process status:"
        echo "=== Whaleon Process ==="
        pgrep -f "whaleon start" && echo "Running" || echo "Not running"
        echo ""
        echo "=== Log Streamer Process ==="
        pgrep -f "log_streamer.py" && echo "Running" || echo "Not running"
        echo ""
        ;;
    logs)
        echo "Recent logs:"
        echo "=== Whaleon Logs (nohup.out) ==="
        tail -20 nohup.out 2>/dev/null || echo "No whaleon logs found"
        echo ""
        echo "=== Log Streamer Logs ==="
        tail -20 log_streamer.out 2>/dev/null || echo "No log streamer logs found"
        echo ""
        ;;
    restart-whaleon)
        echo "Restarting whaleon process..."
        pkill -f "whaleon start"
        sleep 2
        nohup ./whaleon start --headless --max-threads 2 --max-difficulty extra_large_4 --node-id $WHALEON_NODE_ID > nohup.out 2>&1 &
        echo "Whaleon restarted"
        ;;
    restart-log-streamer)
        echo "Restarting log streamer process..."
        pkill -f "log_streamer.py"
        sleep 2
        nohup python3 log_streamer.py --node-id $WHALEON_NODE_ID > log_streamer.out 2>&1 &
        echo "Log streamer restarted"
        ;;
        stop-all)
            echo "Stopping all processes..."
            pkill -f "whaleon start"
            pkill -f "log_streamer.py"
            echo "All processes stopped"
            ;;
    *)
        echo "Usage: $0 {status|logs|restart-whaleon|restart-log-streamer|stop-all}"
        echo ""
        echo "Commands:"
        echo "  status               - Show status of all processes"
        echo "  logs                 - Show recent logs from all processes"
        echo "  restart-whaleon      - Restart only the whaleon process"
        echo "  restart-log-streamer - Restart only the log streamer process"
        echo "  stop-all             - Stop all processes"
        exit 1
        ;;
esac
