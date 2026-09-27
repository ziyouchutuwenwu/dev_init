return {
  -- 类似 VS Code 任务管理系统的插件 (原生支持读取 .vscode/tasks.json 及 mix/cargo/npm/make)
  "stevearc/overseer.nvim",
  cmd = { "OverseerToggle", "OverseerOpen", "OverseerRun", "OverseerBuild", "OverseerTaskAction" },
  opts = {
    strategy = "terminal",
    templates = { "builtin", "vscode" },
    task_list = {
      -- 核心设定：指定方向在左侧，杜绝其私自创建底部输出切分窗口
      direction = "left",
      min_width = 30,
      max_width = { 40, 0.25 },
      default_detail = 1,
    },
  },
  keys = {
    -- Alt 体系（与 Alt+1 文件树、Alt+2 大纲保持一致，全部在左侧统一堆叠）
    {
      "<M-3>",
      function()
        require("overseer").toggle()
      end,
      desc = "切换左侧任务监视面板 (Alt+3)",
    },
    {
      "<M-4>",
      function()
        require("overseer").run_template()
      end,
      desc = "呼出运行任务菜单 (Alt+4)",
    },

    -- Leader 体系（空格键前缀）
    {
      "<Leader>tr",
      function()
        require("overseer").run_template()
      end,
      desc = "运行任务 (Run Task)",
    },
    {
      "<Leader>tt",
      function()
        require("overseer").toggle()
      end,
      desc = "切换任务面板 (Toggle Tasks)",
    },
    {
      "<Leader>ta",
      function()
        require("overseer").task_action()
      end,
      desc = "任务操作 (Task Action)",
    },
    {
      "<Leader>tb",
      "<Cmd>OverseerBuild<CR>",
      desc = "运行构建任务 (Build Task)",
    },
  },
}
