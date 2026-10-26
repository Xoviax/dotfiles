#!/usr/bin/env bash

# Power menu launcher for Hyprland on CachyOS
# Automatically calculates margins so buttons remain a fixed, consistent size
# across all monitors and orientations (landscape, portrait, ultrawide).

# Toggle behavior: if wlogout is already running, close it
if pgrep -x "wlogout" >/dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Rofi powermenu fallback/alternative
if [ "$1" = "--rofi" ]; then
    "$HOME/.config/rofi/powermenu/powermenu.sh"
    exit 0
fi

# Target fixed button dimensions (in pixels)
BTN_W=130
BTN_H=130
COLS=3
ROWS=2
COL_SPACING=20
ROW_SPACING=20

GRID_W=$(( (COLS * BTN_W) + ((COLS - 1) * COL_SPACING) ))
GRID_H=$(( (ROWS * BTN_H) + ((ROWS - 1) * ROW_SPACING) ))

# Query Hyprland for cursor position and active monitor geometry
read -r MON_ID MON_W MON_H < <(python3 -c "
import json, subprocess

try:
    cursor = subprocess.check_output(['hyprctl', 'cursorpos'], timeout=1).decode().strip()
    cx, cy = [int(v.strip()) for v in cursor.split(',')]
    monitors = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j'], timeout=1).decode())

    active = None
    for m in monitors:
        x, y = m['x'], m['y']
        scale = m.get('scale', 1)
        transform = m.get('transform', 0)
        if transform in (1, 3):
            lw = int(m['height'] / scale)
            lh = int(m['width'] / scale)
        else:
            lw = int(m['width'] / scale)
            lh = int(m['height'] / scale)

        if x <= cx < x + lw and y <= cy < y + lh:
            active = (m['id'], lw, lh)
            break

    if not active:
        f = next((m for m in monitors if m.get('focused')), monitors[0])
        scale = f.get('scale', 1)
        transform = f.get('transform', 0)
        if transform in (1, 3):
            active = (f['id'], int(f['height'] / scale), int(f['width'] / scale))
        else:
            active = (f['id'], int(f['width'] / scale), int(f['height'] / scale))

    print(f'{active[0]} {active[1]} {active[2]}')
except Exception:
    print('0 1920 1080')
")

# Calculate margins to center the fixed-size grid exactly
MARGIN_L=$(( (MON_W - GRID_W) / 2 ))
MARGIN_R=$MARGIN_L
MARGIN_T=$(( (MON_H - GRID_H) / 2 ))
MARGIN_B=$MARGIN_T

# Safety clamping
[ "$MARGIN_L" -lt 10 ] && MARGIN_L=10 && MARGIN_R=10
[ "$MARGIN_T" -lt 10 ] && MARGIN_T=10 && MARGIN_B=10

exec wlogout -P "$MON_ID" \
             -b "$COLS" \
             -c "$COL_SPACING" \
             -r "$ROW_SPACING" \
             -L "$MARGIN_L" \
             -R "$MARGIN_R" \
             -T "$MARGIN_T" \
             -B "$MARGIN_B" \
             -s \
             -p layer-shell
