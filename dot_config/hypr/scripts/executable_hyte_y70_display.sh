#!/bin/bash

# Detect if Hyprland is using Lua or legacy Hyprlang
is_lua=false
if hyprctl systeminfo 2>/dev/null | grep -q "configProvider: lua"; then
    is_lua=true
fi

# Dispatch helper compatible with both Lua and Hyprlang engines
dispatch() {
    if [ "$is_lua" = true ]; then
        case "$1" in
            workspace)
                hyprctl dispatch "hl.dsp.focus({ workspace = $2 })"
                ;;
            exec)
                shift
                # Strip leading/trailing quotes if passed
                local cmd="$*"
                cmd="${cmd#\"}"
                cmd="${cmd%\"}"
                hyprctl dispatch "hl.dsp.exec_cmd(\"$cmd\")"
                ;;
            layoutmsg)
                shift
                local arg="$*"
                arg="${arg#\"}"
                arg="${arg%\"}"
                hyprctl dispatch "hl.dsp.layout(\"$arg\")"
                ;;
            movefocus)
                case "$2" in
                    l) dir="left" ;;
                    r) dir="right" ;;
                    u) dir="up" ;;
                    d) dir="down" ;;
                    *) dir="$2" ;;
                esac
                hyprctl dispatch "hl.dsp.focus({ direction = '$dir' })"
                ;;
            *)
                hyprctl dispatch "hl.dsp.exec_raw(\"$*\")"
                ;;
        esac
    else
        hyprctl dispatch "$@"
    fi
}

# 1. Save the ID of the workspace you start on so we can return to it
START_WS=$(hyprctl activeworkspace | grep "workspace ID" | awk '{print $3}')
[ -z "$START_WS" ] && START_WS=1

# 2. Switch to workspace 10 so layout commands apply correctly
dispatch workspace 10

# 3. Launch tclock
dispatch exec "kitty --class sysmon-tclock tclock -c '#cba6f7'"

# Wait a moment for the window to actually render
sleep 0.8

# 4. Tell dwindle layout to split the next window downwards
dispatch layoutmsg "preselect d"

# 5. Launch btop
dispatch exec "kitty --class sysmon-btop --override font_size=7.0 btop"

# Wait for btop to open and grab focus
sleep 0.8

# 6. Move focus back up to the tclock window
dispatch movefocus u

# 7. Shrink the tclock window
dispatch layoutmsg "splitratio -0.69"

# 8. Switch back to the initial workspace
dispatch workspace "$START_WS"
