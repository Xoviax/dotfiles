-- Window Rules & Layer Rules

-- Suppress maximize events
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix XWayland drags
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Hyprland-run window rule
hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})

-- Waybar TUI apps floating rules
hl.window_rule({
    name = "waybar-tui-float",
    match = { class = "^(waybar_.*)$" },
    float = true,
    size = "1000 600",
    center = true,
})

-- Waybar btop floating rule (larger)
hl.window_rule({
    name = "waybar-btop-float",
    match = { class = "waybar_btop" },
    float = true,
    size = "1300 900",
    center = true,
})

-- Wlogout layer rules
hl.layer_rule({
    name = "wlogout-blur",
    match = { namespace = "logout_dialog" },
    blur = true,
    animation = "fade",
})
