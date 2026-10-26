-- Look and Feel Configuration
local mocha = require("colors.mocha")

hl.config({
    general = {
        gaps_in = 7,
        gaps_out = 15,
        border_size = 1,
        col = {
            active_border = mocha.mauve,
            inactive_border = mocha.base,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 20,
        rounding_power = 10,
        active_opacity = 0.999,
        inactive_opacity = 0.86,
        shadow = {
            enabled = true,
            range = 15,
            render_power = 3,
            color = "0xdd1a1a1a",
        },
        blur = {
            enabled = true,
            size = 2,
            passes = 4,
            vibrancy = 0.1696,
        },
    },
})
