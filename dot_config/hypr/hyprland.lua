-- Hyprland Lua Configuration
-- Entry point: ~/.config/hypr/hyprland.lua

-- Ensure ~/.config/hypr is included in package.path for module resolution
local config_dir = os.getenv("HOME") .. "/.config/hypr"
package.path = package.path .. ";" .. config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua"

-- Monitors & Workspaces
require("modules.monitors")

-- Environment Variables
require("modules.env")

-- Autostart Services
require("modules.autostart")

-- Permissions
require("modules.permissions")

-- Look and Feel
require("modules.look_and_feel")

-- Animations & Curves
require("modules.animations")

-- Layout
require("modules.layout")

-- Misc
require("modules.misc")

-- Input & Gestures
require("modules.input")

-- Window & Layer Rules
require("modules.window_rules")

-- Keybindings
require("modules.keybinds")
