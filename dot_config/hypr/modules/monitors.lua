-- Monitors & Workspaces Configuration

hl.env("GDK_SCALE", "1")

-- Display configurations
hl.monitor({
    output = "DP-2",
    mode = "1920x1080@144",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "DP-3",
    mode = "2560x1440@164.83",
    position = "1920x0",
    scale = 1,
})

-- Portrait RIGHT (clockwise)
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@60",
    position = "4480x0",
    scale = 1,
    transform = 1,
})

-- Portrait LEFT (counter-clockwise)
hl.monitor({
    output = "DP-1",
    mode = "3840x1100@60.02",
    position = "5560x0",
    scale = 2,
    transform = 3,
})

-- Workspace persistence mapping
local workspaces = {
    { id = 1, monitor = "DP-3" },
    { id = 2, monitor = "DP-3" },
    { id = 3, monitor = "DP-3" },
    { id = 4, monitor = "DP-3" },
    { id = 5, monitor = "DP-3" },
    { id = 6, monitor = "DP-2" },
    { id = 7, monitor = "DP-2" },
    { id = 8, monitor = "HDMI-A-1" },
    { id = 9, monitor = "HDMI-A-1" },
    { id = 10, monitor = "DP-1" },
}

for _, ws in ipairs(workspaces) do
    hl.workspace_rule({
        workspace = ws.id,
        monitor = ws.monitor,
        persistent = true,
    })
end
