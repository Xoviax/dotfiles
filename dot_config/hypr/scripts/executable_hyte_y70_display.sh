#!/bin/bash

# 1. Save the ID of the workspace you start on so we can return to it
START_WS=$(hyprctl activeworkspace | grep "workspace ID" | awk '{print $3}')

# 2. Switch to workspace 10 so our layout commands apply correctly to the windows
hyprctl dispatch workspace 10

# 3. Launch tclock
hyprctl dispatch exec "kitty --class sysmon-tclock tclock -c '#cba6f7'"

# Wait a moment for the window to actually render (increase if your system boots slowly)
sleep 0.8

# 4. Tell the dwindle layout to force the next window to split downwards
hyprctl dispatch layoutmsg preselect d

# 5. Launch btop
hyprctl dispatch exec "kitty --class sysmon-btop --override font_size=7.0 btop"

# Wait for btop to open and automatically grab window focus
sleep 0.8

# 6. Move focus back up to the tclock window
hyprctl dispatch movefocus u

# 7. Shrink the tclock window 
# A negative ratio shrinks the focused window. Tweak this (-0.1 to -0.5) to get the exact height you want.
hyprctl dispatch layoutmsg splitratio -0.69

# 8. Switch back to the initial workspace
hyprctl dispatch workspace $START_WS
