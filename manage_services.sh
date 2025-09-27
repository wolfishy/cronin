#!/bin/bash

# Nexus Services Management Script
# Manages nohup processes for whaleon, log streamer, and keep-alive

case "$1" in
    status)
        echo "Process status:"
        echo "=== Whaleon Process ==="
        pgrep -f "whaleon start" && echo "Running" || echo "Not running"
        echo ""
        echo "=== Log Streamer Process ==="
        pgrep -f "log_streamer.py" && echo "Running" || echo "Not running"
        echo ""
        echo "=== Keep Alive Process ==="
        pgrep -f "alive.sh" && echo "Running" || echo "Not running"
        ;;
    logs)
        echo "Recent logs from nohup.out:"
        tail -50 nohup.out 2>/dev/null || echo "No nohup output found"
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
        nohup python3 log_streamer.py >> nohup.out 2>&1 &
        echo "Log streamer restarted"
        ;;
    restart-keep-alive)
        echo "Restarting keep alive process..."
        pkill -f "alive.sh"
        sleep 2
        nohup bash ./alive.sh >> nohup.out 2>&1 &
        echo "Keep alive restarted"
        ;;
    stop-all)
        echo "Stopping all processes..."
        pkill -f "whaleon start"
        pkill -f "log_streamer.py"
        pkill -f "alive.sh"
        echo "All processes stopped"
        ;;
    *)
        echo "Usage: $0 {status|logs|restart-whaleon|restart-log-streamer|restart-keep-alive|stop-all}"
        echo ""
        echo "Commands:"
        echo "  status             - Show status of all processes"
        echo "  logs               - Show recent logs from all processes"
        echo "  restart-whaleon    - Restart only the whaleon process"
        echo "  restart-log-streamer - Restart only the log streamer process"
        echo "  restart-keep-alive - Restart only the keep alive process"
        echo "  stop-all           - Stop all processes"
        exit 1
        ;;
esac
