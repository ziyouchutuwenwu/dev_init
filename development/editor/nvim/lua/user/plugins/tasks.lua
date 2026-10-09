local M = {
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
        require("user.plugins.tasks").toggle_task_list()
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
        require("user.plugins.tasks").toggle_task_list()
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

local state = {
  buf = nil,
  tasks_vscode = {},
  line_map = {},
}

local NS_ID = vim.api.nvim_create_namespace("user_overseer_tasks_ns")

function M.find_task_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local b = vim.api.nvim_win_get_buf(win)
      if vim.bo[b].filetype == "overseer_tasks" then
        return win
      end
    end
  end
  return nil
end

local function get_task_status(name)
  local ok, task_list = pcall(require, "overseer.task_list")
  if not ok then return nil, nil end
  local tasks = task_list.list_tasks({
    sort = task_list.sort_newest_first,
  })
  for _, t in ipairs(tasks) do
    if t.name == name then
      return t.status, t
    end
  end
  return nil, nil
end

function M.get_or_create_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end
  local b = vim.api.nvim_create_buf(false, true)
  vim.bo[b].buftype = "nofile"
  vim.bo[b].bufhidden = "hide"
  vim.bo[b].swapfile = false
  vim.bo[b].filetype = "overseer_tasks"
  pcall(vim.api.nvim_buf_set_name, b, "OverseerTasks")

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = b, silent = true, desc = desc })
  end

  map("<CR>", function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local item = state.line_map[lnum]
    if item and item.type == "task" then
      M.run_task(item.task)
    end
  end, "运行任务")

  map("o", function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local item = state.line_map[lnum]
    if item and item.type == "task" then
      local _, task = get_task_status(item.task.name)
      if task then
        require("overseer").run_action(task, "open")
        return
      end
    end
    require("overseer").toggle()
  end, "查看任务输出 / 监视器")

  map("r", function()
    M.refresh(true)
  end, "刷新任务列表")

  map("e", function()
    M.edit_tasks_json()
  end, "编辑 .vscode/tasks.json")

  map("q", function()
    M.close_task_list()
  end, "关闭任务列表")

  map("?", function()
    vim.notify(
      "快捷键说明:\n<Enter>: 运行任务\no: 查看任务输出 / 监视器\nr: 刷新任务列表\ne: 编辑 tasks.json\nq: 关闭面板",
      vim.log.levels.INFO
    )
  end, "显示帮助")

  state.buf = b
  return b
end

function M.edit_tasks_json()
  local cwd = vim.fn.getcwd()
  local tasks_file = cwd .. "/.vscode/tasks.json"
  if vim.fn.filereadable(tasks_file) == 0 then
    local vscode_dir = cwd .. "/.vscode"
    if vim.fn.isdirectory(vscode_dir) == 0 then
      vim.fn.mkdir(vscode_dir, "p")
    end
    local sample = [[{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build",
      "type": "shell",
      "command": "make"
    }
  ]
}]]
    local f = io.open(tasks_file, "w")
    if f then
      f:write(sample)
      f:close()
    end
  end

  if package.loaded["edgy"] then
    local main_wins = require("edgy.editor").list_wins().main
    if not main_wins[vim.api.nvim_get_current_win()] then
      require("edgy.editor").goto_main()
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(tasks_file))
end

function M.load_tasks(callback)
  local ok_vs, vs_util = pcall(require, "overseer.vscode.vs_util")
  local vs_tasks = {}
  if ok_vs then
    local path = vs_util.get_tasks_file(vim.fn.getcwd())
    if path and vim.fn.filereadable(path) == 1 then
      local ok_load, content = pcall(vs_util.load_tasks_file, path)
      if ok_load and content and content.tasks then
        for _, t in ipairs(content.tasks) do
          local name = t.label or t.name
          if name then
            table.insert(vs_tasks, {
              name = name,
              command = t.command or (type(t.args) == "table" and table.concat(t.args, " ")) or "",
              group = type(t.group) == "table" and t.group.kind or t.group,
              is_vscode = true,
            })
          end
        end
      end
    end
  end
  state.tasks_vscode = vs_tasks

  if callback then
    callback()
  end
end

function M.render()
  local b = M.get_or_create_buf()
  local win = M.find_task_window()
  local cursor = nil
  if win and vim.api.nvim_win_is_valid(win) then
    cursor = vim.api.nvim_win_get_cursor(win)
  end

  state.line_map = {}
  local lines = {}
  local highlights = {}

  local function add_line(text, hl, col_s, col_e)
    table.insert(lines, text)
    local lnum = #lines
    if hl then
      table.insert(highlights, { lnum = lnum - 1, col_start = col_s or 0, col_end = col_e or -1, hl = hl })
    end
    return lnum
  end

  local vs_count = #state.tasks_vscode
  if vs_count == 0 then
    add_line("  (未定义任务，按 e 编辑)", "Comment")
  else
    for _, t in ipairs(state.tasks_vscode) do
      local status = get_task_status(t.name)
      local icon = "  󰐊 "
      local icon_hl = "Directory"
      local status_str = ""

      if status == "RUNNING" then
        icon = "  ● "
        icon_hl = "DiagnosticWarn"
        status_str = " (运行中...)"
      elseif status == "SUCCESS" then
        icon = "  ✓ "
        icon_hl = "DiagnosticOk"
        status_str = " (成功)"
      elseif status == "FAILURE" then
        icon = "  ✗ "
        icon_hl = "DiagnosticError"
        status_str = " (失败)"
      elseif status == "CANCELED" then
        icon = "  󰜺 "
        icon_hl = "Comment"
        status_str = " (已取消)"
      end

      local text = string.format("%s%-14s%s", icon, t.name, status_str)
      local l = add_line(text)
      table.insert(highlights, { lnum = l - 1, col_start = 2, col_end = #icon, hl = icon_hl })
      table.insert(highlights, { lnum = l - 1, col_start = #icon, col_end = #icon + #t.name, hl = "Function" })
      if status_str ~= "" then
        table.insert(highlights, { lnum = l - 1, col_start = #icon + #t.name, col_end = -1, hl = icon_hl })
      end

      state.line_map[l] = { type = "task", task = t }
    end
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = b })
  vim.api.nvim_set_option_value("readonly", false, { buf = b })
  vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = b })
  vim.api.nvim_set_option_value("readonly", true, { buf = b })

  vim.api.nvim_buf_clear_namespace(b, NS_ID, 0, -1)
  for _, h in ipairs(highlights) do
    pcall(vim.api.nvim_buf_add_highlight, b, NS_ID, h.hl, h.lnum, h.col_start, h.col_end)
  end

  if win and vim.api.nvim_win_is_valid(win) and cursor then
    local max_line = #lines
    local row = math.min(math.max(1, cursor[1]), max_line)
    pcall(vim.api.nvim_win_set_cursor, win, { row, cursor[2] })
  end
end

function M.run_task(task_item)
  local overseer = require("overseer")
  local template = require("overseer.template")

  if task_item.template then
    template.build_task(task_item.template, { params = {} }, function(err, task)
      if err then
        vim.notify("创建任务失败: " .. tostring(err), vim.log.levels.ERROR)
      elseif task then
        task:start()
        vim.notify("已启动任务: " .. task.name, vim.log.levels.INFO)
        M.render()
      end
    end)
    return
  end

  template.get_by_name(task_item.name, { dir = vim.fn.getcwd() }, function(tmpl)
    if tmpl then
      template.build_task(tmpl, { params = {} }, function(err, task)
        if err then
          vim.notify("创建任务失败: " .. tostring(err), vim.log.levels.ERROR)
        elseif task then
          task:start()
          vim.notify("已启动任务: " .. task.name, vim.log.levels.INFO)
          M.render()
        end
      end)
    else
      if task_item.command and task_item.command ~= "" then
        local t = overseer.new_task({
          name = task_item.name,
          cmd = task_item.command,
          components = { "default" },
        })
        t:start()
        vim.notify("已启动命令任务: " .. task_item.name, vim.log.levels.INFO)
        M.render()
      else
        vim.notify("未找到任务模板或命令: " .. task_item.name, vim.log.levels.WARN)
      end
    end
  end)
end

function M.refresh(notify_user)
  pcall(function()
    require("overseer.template").clear_cache({ dir = vim.fn.getcwd() })
  end)
  M.load_tasks(function()
    M.render()
    if notify_user then
      vim.notify("任务列表已同步更新", vim.log.levels.INFO)
    end
  end)
end

function M.open_task_list()
  local win = M.find_task_window()
  if win then
    vim.api.nvim_set_current_win(win)
    M.refresh(false)
    return win
  end

  local buf = M.get_or_create_buf()
  if package.loaded["edgy"] then
    local main_wins = require("edgy.editor").list_wins().main
    if not main_wins[vim.api.nvim_get_current_win()] then
      require("edgy.editor").goto_main()
    end
  end

  vim.cmd("vsplit")
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = true

  M.refresh(false)
  return win
end

function M.close_task_list()
  local win = M.find_task_window()
  if win then
    vim.api.nvim_win_close(win, true)
  end
end

function M.toggle_task_list()
  local win = M.find_task_window()
  if win then
    M.close_task_list()
  else
    M.open_task_list()
  end
end

local augroup = vim.api.nvim_create_augroup("UserOverseerTasksAutoSync", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost", "FileChangedShellPost" }, {
  group = augroup,
  pattern = { "*/.vscode/tasks.json", "*tasks.json" },
  callback = function()
    M.refresh(false)
  end,
  desc = "当 tasks.json 变动时自动同步任务列表",
})

vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "OverseerListUpdate",
  callback = function()
    if M.find_task_window() then
      M.render()
    end
  end,
  desc = "当 Overseer 任务状态变动时更新任务列表显示",
})

return M
