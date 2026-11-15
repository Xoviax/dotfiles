#!/usr/bin/env bash
# ==============================================================================
# hyte_y70_kde.sh
# Open tclock + btop on the Hyte Y70 touch display in KDE Plasma (Wayland)
# ==============================================================================

set -euo pipefail

# Ensure we only execute inside KDE Plasma
if [[ "${XDG_CURRENT_DESKTOP:-}" != *"KDE"* ]]; then
    echo "Current desktop is '${XDG_CURRENT_DESKTOP:-unknown}'. This script is intended for KDE Plasma."
    exit 0
fi

ACTION="start"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--restart)
            ACTION="restart"
            shift
            ;;
        -k|--stop)
            ACTION="stop"
            shift
            ;;
        -s|--status)
            ACTION="status"
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo "Options:"
            echo "  -r, --restart   Restart tclock and btop on Hyte Y70"
            echo "  -k, --stop      Stop running sysmon instances"
            echo "  -s, --status    Check running status"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

stop_instances() {
    pkill -f "kitty --class sysmon-tclock" 2>/dev/null || true
    pkill -f "kitty --class sysmon-btop" 2>/dev/null || true
}

check_status() {
    local tclock_running=false
    local btop_running=false
    if pgrep -f "kitty --class sysmon-tclock" >/dev/null 2>&1; then
        tclock_running=true
    fi
    if pgrep -f "kitty --class sysmon-btop" >/dev/null 2>&1; then
        btop_running=true
    fi
    echo "sysmon-tclock running: $tclock_running"
    echo "sysmon-btop   running: $btop_running"
}

if [[ "$ACTION" == "stop" ]]; then
    echo "Stopping Hyte Y70 sysmon instances..."
    stop_instances
    exit 0
fi

if [[ "$ACTION" == "status" ]]; then
    check_status
    exit 0
fi

if [[ "$ACTION" == "restart" ]]; then
    echo "Restarting Hyte Y70 sysmon instances..."
    stop_instances
    sleep 0.5
fi

# Detect DP-1 (Hyte Y70 display) geometry
SCREEN_INFO=$(python3 - << 'EOF'
import subprocess, re
# Fallback defaults
x, y, w, h = 5560, 0, 550, 1920
try:
    out = subprocess.check_output(['kscreen-doctor', '-o'], text=True)
    blocks = out.split('Output: ')
    for b in blocks:
        if 'DP-1' in b and 'enabled' in b:
            m = re.search(r'Geometry:\s*(\d+),(\d+)\s+(\d+)x(\d+)', b)
            if m:
                x, y, w, h = map(int, m.groups())
                break
except Exception:
    pass
print(f"{x} {y} {w} {h}")
EOF
)

read -r DP_X DP_Y DP_W DP_H <<< "$SCREEN_INFO"

# Proportions: tclock gets ~380px at top, btop takes the rest of the height
TCLOCK_H=380
BTOP_Y=$((DP_Y + TCLOCK_H))
BTOP_H=$((DP_H - TCLOCK_H))

# Ensure KWin window rules are up-to-date in ~/.config/kwinrulesrc
update_kwin_rules() {
    local dp_x="$1"
    local dp_y="$2"
    local dp_w="$3"
    local tclock_h="$4"
    local btop_y="$5"
    local btop_h="$6"

    local current_order
    current_order=$(kreadconfig6 --file kwinrulesrc --group "General" --key "Order" 2>/dev/null || echo "")
    local new_order="$current_order"
    for r in "sysmon-tclock" "sysmon-btop"; do
        if [[ ! ",$new_order," =~ ,"$r", ]]; then
            if [[ -z "$new_order" ]]; then
                new_order="$r"
            else
                new_order="$new_order,$r"
            fi
        fi
    done
    if [[ "$new_order" != "$current_order" ]]; then
        kwriteconfig6 --file kwinrulesrc --group "General" --key "Order" "$new_order"
        kwriteconfig6 --file kwinrulesrc --group "General" --key "rules" "$new_order"
    fi

    # Update sysmon-tclock rule
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "Description" "Sysmon tclock on Hyte Y70"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "wmclass" "sysmon-tclock"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "wmclassmatch" "1"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "position" "${dp_x},${dp_y}"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "positionrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "size" "${dp_w},${tclock_h}"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "sizerule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "noborder" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "noborderrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "desktops" ""
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "desktopsrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "skiptaskbar" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "skiptaskbarrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "skippager" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "skippagerrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "skipswitcher" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "skipswitcherrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "ignoregeometry" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-tclock" --key "ignoregeometryrule" "2"

    # Update sysmon-btop rule
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "Description" "Sysmon btop on Hyte Y70"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "wmclass" "sysmon-btop"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "wmclassmatch" "1"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "position" "${dp_x},${btop_y}"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "positionrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "size" "${dp_w},${btop_h}"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "sizerule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "noborder" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "noborderrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "desktops" ""
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "desktopsrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "skiptaskbar" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "skiptaskbarrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "skippager" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "skippagerrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "skipswitcher" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "skipswitcherrule" "2"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "ignoregeometry" "true"
    kwriteconfig6 --file kwinrulesrc --group "sysmon-btop" --key "ignoregeometryrule" "2"

    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
}

update_kwin_rules "$DP_X" "$DP_Y" "$DP_W" "$TCLOCK_H" "$BTOP_Y" "$BTOP_H"

# Launch tclock if not running
if ! pgrep -f "kitty --class sysmon-tclock" >/dev/null 2>&1; then
    setsid -f kitty --class sysmon-tclock tclock -c '#cba6f7' >/dev/null 2>&1
fi

# Launch btop if not running
if ! pgrep -f "kitty --class sysmon-btop" >/dev/null 2>&1; then
    setsid -f kitty --class sysmon-btop --override font_size=7.0 btop >/dev/null 2>&1
fi
