local is_ssh = vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil

local has_gui_clipboard = vim.env.DISPLAY ~= nil or 
                         vim.env.WAYLAND_DISPLAY ~= nil or 
                         vim.env.XDG_SESSION_TYPE == "wayland"

if is_ssh and not has_gui_clipboard then
  vim.g.clipboard = {
    name = "osc 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end

return {}