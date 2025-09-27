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
        echo ""
        echo "=== Keep Alive Server Process ==="
        pgrep -f "keepalive_server.py" && echo "Running" || echo "Not running"
        ;;
    logs)
        echo "Recent logs:"
        echo "=== Whaleon Logs (nohup.out) ==="
        tail -20 nohup.out 2>/dev/null || echo "No whaleon logs found"
        echo ""
        echo "=== Log Streamer Logs ==="
        tail -20 log_streamer.out 2>/dev/null || echo "No log streamer logs found"
        echo ""
        echo "=== Keep Alive Logs ==="
        tail -20 keep_alive.out 2>/dev/null || echo "No keep alive logs found"
        echo ""
        echo "=== Keep Alive Server Logs ==="
        tail -20 keepalive_server.out 2>/dev/null || echo "No keep alive server logs found"
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
        restart-keep-alive)
            echo "Restarting keep alive process..."
            pkill -f "alive.sh"
            sleep 2
            nohup bash ./alive.sh > keep_alive.out 2>&1 &
            echo "Keep alive restarted"
            ;;
        restart-keep-alive-server)
            echo "Restarting keep alive server process..."
            pkill -f "keepalive_server.py"
            sleep 2
            nohup python3 keepalive_server.py > keepalive_server.out 2>&1 &
            echo "Keep alive server restarted"
            ;;
        stop-all)
            echo "Stopping all processes..."
            pkill -f "whaleon start"
            pkill -f "log_streamer.py"
            pkill -f "alive.sh"
            pkill -f "keepalive_server.py"
            echo "All processes stopped"
            ;;
    *)
        echo "Usage: $0 {status|logs|restart-whaleon|restart-log-streamer|restart-keep-alive|restart-keep-alive-server|stop-all}"
        echo ""
        echo "Commands:"
        echo "  status                    - Show status of all processes"
        echo "  logs                      - Show recent logs from all processes"
        echo "  restart-whaleon           - Restart only the whaleon process"
        echo "  restart-log-streamer      - Restart only the log streamer process"
        echo "  restart-keep-alive        - Restart only the keep alive process"
        echo "  restart-keep-alive-server - Restart only the keep alive server process"
        echo "  stop-all                  - Stop all processes"
        exit 1
        ;;
esac
