return {
  -- 1. 禁用会话管理插件，不保存或恢复任何上次会话
  {
    "stevearc/resession.nvim",
    enabled = false,
  },

  -- 2. 彻底禁用 ShaDa 文件读写与历史记录，不向磁盘记录任何文件访问、标记或跳转历史
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
      -- 彻底清空并阻止维护内存中的 v:oldfiles 最近打开文件列表
      vim.v.oldfiles = {}
      vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
        callback = function()
          vim.v.oldfiles = {}
        end,
        desc = "禁止记录最近打开文件历史",
      })

      -- 阻止 snacks.picker 记录搜索与查找历史到磁盘 (*.history)
      pcall(function()
        local hist = require("snacks.picker.util.history")
        hist.record = function() end
      end)
    end,
  },
}