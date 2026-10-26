-- Autostart Processes

-- Execute daemons and startup scripts once on Hyprland startup
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    -- Allow compositor display initialization before launching display automation
    hl.exec_cmd("sleep 1 && ~/.config/hypr/scripts/hyte_y70_display.sh")
end)
