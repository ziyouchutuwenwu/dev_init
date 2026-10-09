return {
  "stevearc/overseer.nvim",
  cmd = { "OverseerToggle", "OverseerOpen", "OverseerRun", "OverseerBuild", "OverseerTaskAction" },
  opts = {
    strategy = "terminal",
    templates = { "builtin", "vscode" },
    task_list = {
      direction = "left",
      width = 32,
      min_width = 1,
      max_width = { 100, 0.5 },
      default_detail = 1,
    },
  },
  keys = {
    {
      "<M-3>",
      function()
        require("plugins.modules.tasks").toggle_task_list()
      end,
      desc = "切换任务列表 (Alt+3)",
    },
    {
      "<M-4>",
      function()
        require("overseer").run_template()
      end,
      desc = "呼出运行任务选择菜单 (Alt+4)",
    },
    {
      "<Leader>tt",
      function()
        require("plugins.modules.tasks").toggle_task_list()
      end,
      desc = "切换任务列表 (Toggle Task List)",
    },
    {
      "<Leader>tr",
      function()
        require("overseer").run_template()
      end,
      desc = "运行任务 (Run Task)",
    },
    {
      "<Leader>to",
      function()
        require("overseer").toggle()
      end,
      desc = "切换任务监视器 (Toggle Task Monitor)",
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
