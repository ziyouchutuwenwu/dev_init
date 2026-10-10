return {
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
        "overseer_tasks",
        "nofile",
        "prompt",
        "quickfix",
      },
      open_files_in_last_window = true,
      filesystem = {
        filtered_items = {
          visible = true,
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
            "overseer_tasks",
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

  {
    "stevearc/oil.nvim",
    opts = {
      default_file_explorer = false,
      view_options = {
        show_hidden = true,
      },
    },
    keys = {
      { "-", "<Cmd>Oil<CR>", desc = "以缓冲区模式编辑当前目录 (Oil)" },
    },
  },
}
