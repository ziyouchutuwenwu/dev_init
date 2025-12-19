return {
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, _)
      -- 剪贴板支持
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
    end,
  }
}
