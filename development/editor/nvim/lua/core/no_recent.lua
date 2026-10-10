return {
  {
    "stevearc/resession.nvim",
    enabled = false,
  },

  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      if not opts.options then opts.options = {} end
      if not opts.options.opt then opts.options.opt = {} end
      opts.options.opt.shada = ""
      opts.options.opt.shadafile = "NONE"
      return opts
    end,
    init = function()

      vim.v.oldfiles = {}
      vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
        callback = function()
          vim.v.oldfiles = {}
        end,
        desc = "禁止记录最近打开文件历史",
      })

      pcall(function()
        local hist = require("snacks.picker.util.history")
        hist.record = function() end
      end)
    end,
  },
}
