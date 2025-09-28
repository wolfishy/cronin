#!/bin/bash

# Nexus Services Management Script
# Manages nohup processes for whaleon and log streamer

case "$1" in
    status)
        echo "Process status:"
        echo "=== Whaleon Process ==="
        pgrep -f "whaleon start" && echo "Running" || echo "Not running"
        echo ""
        echo "=== Log Monitor Process ==="
        pgrep -f "log_monitor.py" && echo "Running" || echo "Not running"
        echo ""
        ;;
    logs)
        echo "Recent logs:"
        echo "=== Whaleon Logs (nohup.out) ==="
        tail -20 nohup.out 2>/dev/null || echo "No whaleon logs found"
        echo ""
        echo "=== Log Monitor Logs ==="
        tail -20 log_monitor.out 2>/dev/null || echo "No log monitor logs found"
        echo ""
        echo "=== Latest Whaleon Output ==="
        cat /tmp/latest_whaleon_output.txt 2>/dev/null || echo "No latest output saved yet"
        echo ""
        ;;
    restart)
        echo "Restarting whaleon process..."
        pkill -f "whaleon start"
        pkill -f "log_monitor.py"
        sleep 2
        nohup taskset -c 0-11 ./whaleon start --headless --max-threads 24 --max-difficulty extra_large_4 --node-id $WHALEON_ID > nohup.out 2>&1 &
        # nohup python3 log_monitor.py $WHALEON_ID > log_monitor.out 2>&1 &
        echo "Whaleon restarted"
        ;;
    stop-all)
        echo "Stopping all processes..."
        pkill -f "whaleon start"
        echo "All processes stopped"
        ;;
    *)
        echo "Usage: $0 {status|logs|restart-whaleon|restart-log-monitor|stop-all}"
        echo ""
        echo "Commands:"
        echo "  status               - Show status of all processes"
        echo "  logs                 - Show recent logs from all processes"
        echo "  restart              - Restart only the whaleon process"
        echo "  stop-all             - Stop all processes"
        exit 1
        ;;
esac
