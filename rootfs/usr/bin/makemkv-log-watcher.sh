#!/bin/sh
# Watch for MakeMKV log file and tail it to stdout when it appears

LOG_FILE="/config/MakeMKV_log.txt"
MONITOR_SCRIPT="/usr/bin/makemkv-monitor.sh"

echo "[log-watcher] Starting MakeMKV log watcher..."

# Wait for log file to exist
while [ ! -f "$LOG_FILE" ]; do
    sleep 2
done

echo "[log-watcher] Found MakeMKV log at $LOG_FILE, starting tail..."

# Tail the log file starting from end (don't process old entries)
# -n0 means start with 0 lines from existing file, only show new additions
tail -n0 -f "$LOG_FILE" 2>/dev/null | $MONITOR_SCRIPT