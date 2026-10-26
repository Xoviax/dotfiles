#!/usr/bin/env bash

# Power menu launcher for Hyprland
# Toggle behavior: if powermenu or wlogout is already running, close it
if pgrep -f "powermenu.py" >/dev/null; then
    pkill -f "powermenu.py"
    exit 0
fi

if pgrep -x "wlogout" >/dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Rofi powermenu fallback/alternative
if [ "$1" = "--rofi" ]; then
    "$HOME/.config/rofi/powermenu/powermenu.sh"
    exit 0
fi

# Legacy wlogout fallback
if [ "$1" = "--wlogout" ]; then
    exec wlogout -b 6 -c 20 -r 20 -p layer-shell
fi

# Execute modern Liquid Glass Layer Shell powermenu
exec "$HOME/.config/hypr/scripts/powermenu.py"
