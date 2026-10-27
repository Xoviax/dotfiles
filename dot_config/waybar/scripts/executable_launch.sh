#!/bin/bash

# Kill any existing waybar processes
pkill -x waybar
pkill -x swaync

# Wait for processes to exit
sleep 0.3

# Ensure IPC compatibility bridge is running
BRIDGE="$HOME/.config/hypr/scripts/hypr-ipc-bridge.py"
if [ -f "$BRIDGE" ] && ! pgrep -f "hypr-ipc-bridge.py" >/dev/null; then
    setsid -f python3 "$BRIDGE" >/dev/null 2>&1
    sleep 0.1
fi

# Launch waybar and swaync fully detached
setsid -f /home/xoviax/.local/bin/waybar >/dev/null 2>&1
setsid -f swaync >/dev/null 2>&1
