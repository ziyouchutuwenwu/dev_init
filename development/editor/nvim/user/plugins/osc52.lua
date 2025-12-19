return {
  {
    "ojroques/nvim-osc52",
    opts = {
      max_length = 0,           -- 最大长度限制 (0 表示无限制)
      silent = true,            -- 禁用成功复制时的消息
      trim = false,             -- 复制前是否去除空白字符
      tmux_passthrough = true,  -- 使用 tmux 直通 (需要 tmux: set -g allow-passthrough on)
    },
    config = function(_, opts)
      require("osc52").setup(opts)

      -- 始终使用 unnamedplus，让无名寄存器使用系统剪贴板
      vim.opt.clipboard = "unnamedplus"

      -- 在 SSH/TMUX 环境下使用 osc52 作为剪贴板提供者
      if vim.env.SSH_CLIENT or vim.env.SSH_TTY or vim.env.TMUX then
        vim.g.clipboard = {
          name = "osc52",
          copy = {
            ["+"] = require("osc52").copy,
            ["*"] = require("osc52").copy,
          },
          paste = {
            ["+"] = require("osc52").paste,
            ["*"] = require("osc52").paste,
          },
        }
      end
    end,
  },
}