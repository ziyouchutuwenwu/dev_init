local wezterm = require 'wezterm'

return {
    -- 和 terminator 保持一致
    keys = {
        {
            key = 'e',
            mods = 'CTRL|SHIFT',
            action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain'},
        },
        {
            key = 'o',
            mods = 'CTRL|SHIFT',
            action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
        },
    },
}