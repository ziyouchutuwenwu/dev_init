local ui = require('settings.ui')
local keymap = require('settings.keymap')

local config = {}

config.warn_about_missing_glyphs = false
config.keys = keymap.keys
config.font = ui.font
config.skip_close_confirmation_for_processes_named = {
  'bash',
  'sh',
  'zsh',
  'zellij',
  "vim",
  "nvim",
  "emacs",
}
config.window_close_confirmation = 'NeverPrompt'
config.initial_cols = ui.initial_cols
config.initial_rows = ui.initial_rows

return config
