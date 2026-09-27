return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    if not opts.options then opts.options = {} end
    if not opts.options.opt then opts.options.opt = {} end
    -- 取消全局劫持：让 dd, yy, p 等原生操作完全留在 nvim 内部寄存器运作，绝不污染系统剪贴板
    opts.options.opt.clipboard = ""
    return opts
  end,
  init = function()
    -- 启用 Ghostty 原生 OSC 52 剪贴板后端（供 Ctrl+c / Ctrl+v / Ctrl+x 专享系统剪贴板通道）
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
    vim.opt.clipboard = ""
  end,
}