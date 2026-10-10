local M = {}

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
  local ok, term_mgr = pcall(require, "plugins.modules.terminal")
  if not ok or not term_mgr or not term_mgr.task_statuses then
    ok, term_mgr = pcall(require, "user.plugins.terminal")
  end
  if ok and term_mgr and term_mgr.task_statuses and term_mgr.task_statuses[name] then
    return term_mgr.task_statuses[name], nil
  end
  local ok_ov, task_list = pcall(require, "overseer.task_list")
  if not ok_ov then return nil, nil end
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

  local function execute_task_at_cursor(from_mouse)
    local lnum = nil
    if from_mouse then
      local mouse = vim.fn.getmousepos()
      if mouse and mouse.line > 0 then
        if mouse.winid > 0 and mouse.winid ~= vim.api.nvim_get_current_win() then
          vim.api.nvim_set_current_win(mouse.winid)
        end
        pcall(vim.api.nvim_win_set_cursor, 0, { mouse.line, 0 })
        lnum = mouse.line
      end
    end
    if not lnum then
      lnum = vim.api.nvim_win_get_cursor(0)[1]
    end
    local item = state.line_map[lnum]
    if item and item.type == "task" then
      M.run_task(item.task)
    end
  end

  local function select_task_at_cursor()
    local mouse = vim.fn.getmousepos()
    if mouse and mouse.line > 0 then
      if mouse.winid > 0 and mouse.winid ~= vim.api.nvim_get_current_win() then
        vim.api.nvim_set_current_win(mouse.winid)
      end
      vim.wo.cursorline = true
      pcall(vim.api.nvim_win_set_cursor, 0, { mouse.line, 0 })
    end
  end

  map("<LeftMouse>", function()
    select_task_at_cursor()
  end, "单击选中任务")

  map("<CR>", function()
    execute_task_at_cursor(false)
  end, "运行任务")

  map("<2-LeftMouse>", function()
    execute_task_at_cursor(true)
  end, "双击运行任务")

  map("o", function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local item = state.line_map[lnum]
    if item and item.type == "task" then
      local term_mgr = require("plugins.modules.terminal")
      for i, t in ipairs(term_mgr.terminals) do
        if t.task_name == item.task.name then
          term_mgr.switch_terminal(i)
          term_mgr.open()
          return
        end
      end
    end
    require("plugins.modules.terminal").open()
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
            local cmd = t.command or ""
            if type(t.args) == "table" and #t.args > 0 then
              cmd = (cmd ~= "" and (cmd .. " ") or "") .. table.concat(t.args, " ")
            end
            table.insert(vs_tasks, {
              name = name,
              command = cmd,
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

      if status == "RUNNING" then
        icon = "  ● "
        icon_hl = "DiagnosticWarn"
      elseif status == "SUCCESS" then
        icon = "  ✓ "
        icon_hl = "DiagnosticOk"
      elseif status == "FAILURE" then
        icon = "  ✗ "
        icon_hl = "DiagnosticError"
      elseif status == "CANCELED" then
        icon = "  󰜺 "
        icon_hl = "Comment"
      end

      local text = string.format("%s%s", icon, t.name)
      local l = add_line(text)
      table.insert(highlights, { lnum = l - 1, col_start = 2, col_end = #icon, hl = icon_hl })
      table.insert(highlights, { lnum = l - 1, col_start = #icon, col_end = #icon + #t.name, hl = "Function" })

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
  local term_mgr = require("plugins.modules.terminal")
  term_mgr.run_task(task_item)
  M.render()
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
  vim.wo[win].statusline = ""

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

package.loaded["plugins.modules.tasks"] = M
package.loaded["plugins.tasks"] = M
package.loaded["user.tasks"] = M
package.loaded["user.plugins.tasks"] = M
package.loaded["user.modules.tasks"] = M
return M
