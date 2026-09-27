return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  keys = {
    -- 1. 全局替换：<Space>gr (Global Replace)
    {
      "<Leader>gr",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        local prefills = {
          filesFilter = (ext and ext ~= "") and ("*." .. ext) or nil,
        }
        if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
          grug.with_visual_selection({ prefills = prefills })
        else
          grug.open({ prefills = prefills })
        end
      end,
      mode = { "n", "v" },
      desc = "全局替换 (Global Replace 面板)",
    },
    -- 2. 当前文件替换：<Space>lr (Local Replace)
    {
      "<Leader>lr",
      function()
        local grug = require("grug-far")
        local file = vim.fn.expand("%")
        if file == "" then
          vim.notify("当前缓冲区无文件", vim.log.levels.WARN)
          return
        end
        local prefills = {
          paths = file,
        }
        if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
          grug.with_visual_selection({ prefills = prefills })
        else
          grug.open({ prefills = prefills })
        end
      end,
      mode = { "n", "v" },
      desc = "当前文件替换 (Local Replace 面板)",
    },
    -- 兼容别名
    {
      "<Leader>sr",
      function()
        require("grug-far").open()
      end,
      mode = { "n", "v" },
      desc = "全局搜索与替换 (Grug-far)",
    },
    {
      "<Leader>sw",
      function()
        require("grug-far").open({
          prefills = {
            search = vim.fn.expand("<cword>"),
          },
        })
      end,
      mode = "n",
      desc = "全局替换光标词",
    },
  },
  opts = {
    headerMaxWidth = 80,
    history = {
      maxHistoryLines = 0,
      autoSave = {
        enabled = false,
      },
    },
    keymaps = {
      replace = { n = "<localleader>r" },
      qflist = { n = "<localleader>q" },
      syncLocations = { n = "<localleader>s" },
      syncLine = { n = "<localleader>l" },
      close = { n = "q" },
      historyOpen = { n = "<localleader>t" },
      historyAdd = { n = "<localleader>a" },
      refresh = { n = "<localleader>f" },
      openLocation = { n = "<localleader>o" },
      gotoLocation = { n = "<Enter>" },
      pin = { n = "<localleader>p" },
      abort = { n = "<localleader>b" },
      help = { n = "g?" },
      toggleShowExcluded = { n = "<localleader>e" },
    },
  },
}
