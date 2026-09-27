-- 取消全局劫持：让 dd, yy, p 等原生操作完全留在 nvim 内部寄存器运作，绝不污染系统剪贴板
vim.opt.clipboard = ""
vim.opt.mouse = "a"

-- 启用 Ghostty 原生 OSC 52 剪贴板后端（供 Ctrl+C / Ctrl+V / Ctrl+X 专享系统剪贴板通道）
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