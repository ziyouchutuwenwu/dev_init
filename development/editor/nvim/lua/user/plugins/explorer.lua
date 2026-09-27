return {
  -- 侧边栏文件浏览 (Neo-tree 增强)
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      open_files_do_not_replace_types = {
        "terminal",
        "Trouble",
        "trouble",
        "qf",
        "edgy",
        "edgy-preview",
        "aerial",
        "OverseerList",
        "OverseerOutput",
        "nofile",
        "prompt",
        "quickfix",
      },
      open_files_in_last_window = true,
      filesystem = {
        filtered_items = {
          visible = true, -- 显示隐藏文件但降低对比度
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = { enabled = true },
      },
    },
    keys = {
      { "<M-1>", "<Cmd>Neotree toggle<CR>", desc = "切换侧边栏文件树 (Alt+1)" },
      { "<Leader>e", "<Cmd>Neotree toggle<CR>", desc = "切换侧边栏文件树" },
    },
  },

  -- 窗口选择器增强：确保窗口拾取器不会误选大纲、任务监视器等侧边栏
  {
    "s1n7ax/nvim-window-picker",
    opts = {
      filter_rules = {
        autoselect_one = true,
        include_current_win = false,
        bo = {
          filetype = {
            "NvimTree",
            "neo-tree",
            "notify",
            "snacks_notif",
            "aerial",
            "OverseerList",
            "OverseerOutput",
            "trouble",
            "Trouble",
            "qf",
            "edgy",
          },
          buftype = { "terminal", "quickfix", "nofile", "prompt", "help" },
        },
      },
    },
  },

  -- 缓冲区快速文件管理 (Oil.nvim: 像编辑普通文本一样重命名/新建文件)
  {
    "stevearc/oil.nvim",
    opts = {
      default_file_explorer = false, -- 保留 neo-tree 为默认侧边栏
      view_options = {
        show_hidden = true,
      },
    },
    keys = {
      { "-", "<Cmd>Oil<CR>", desc = "以缓冲区模式编辑当前目录 (Oil)" },
    },
  },
}
