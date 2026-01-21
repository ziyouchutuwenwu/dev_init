local has_gui_clipboard =
  vim.env.DISPLAY ~= nil or
  vim.env.WAYLAND_DISPLAY ~= nil or
  vim.env.XDG_SESSION_TYPE == "wayland"

if not has_gui_clipboard then
  vim.g.clipboard = {
    name = "osc52",
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