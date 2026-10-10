local M = {}

M.terminals = {}
M.current_idx = 1
M.task_statuses = {}
M.term_win = nil
M.list_win = nil
M.list_buf = nil
M.line_map = {}
local function get_target_list_width()
  local cols = vim.o.columns
  if cols <= 100 then
    return 8
  elseif cols <= 140 then
    return 9
  elseif cols <= 180 then
    return 10
  else
    return 11
  end
end

M.height_ratio = 0.28
M.height = 12
M.list_width = get_target_list_width()
M.last_screen_lines = vim.o.lines

local NS_ID = vim.api.nvim_create_namespace("user_term_list_ns")

local function get_target_height()
  local lines = vim.o.lines
  local ratio = M.height_ratio or 0.28
  local h = math.floor(lines * ratio)
  return math.max(math.min(h, math.floor(lines * 0.65)), 5)
end

function M.is_open()
  return M.term_win ~= nil
    and vim.api.nvim_win_is_valid(M.term_win)
    and M.list_win ~= nil
    and vim.api.nvim_win_is_valid(M.list_win)
end

function M.get_active_terminal()
  if #M.terminals == 0 then
    return nil
  end
  if M.current_idx < 1 or M.current_idx > #M.terminals then
    M.current_idx = #M.terminals
  end
  return M.terminals[M.current_idx]
end

function M.update_winbar(active)
  if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    vim.wo[M.term_win].winbar = ""
  end
  if M.list_win and vim.api.nvim_win_is_valid(M.list_win) then
    vim.wo[M.list_win].winbar = ""
  end
end

_G.user_term_click_new = function()
  M.create_terminal()
end

function M.handle_list_click(mouse)
  if not mouse then
    return
  end
  local lnum = (mouse.line and mouse.line > 0) and mouse.line or mouse.winrow
  if not lnum or lnum <= 0 then
    return
  end

  local item = M.line_map[lnum]
  if not item then
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      vim.schedule(function()
        M.scroll_to_prompt()
      end)
    end
    return
  end

  if item.is_plus then
    local plus_col = item.plus_col or (math.floor((M.list_width - 1) / 2) + 1)
    local click_col = (mouse.wincol and mouse.wincol > 0) and mouse.wincol or mouse.column
    if click_col and click_col >= plus_col - 1 and click_col <= plus_col + 1 then
      M.create_terminal()
      return
    end
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      vim.schedule(function()
        M.scroll_to_prompt()
      end)
    end
    return
  end

  if item.id then
    local close_col = math.max(1, M.list_width - 2)
    local on_x = (mouse.wincol >= close_col)
    if on_x then
      M.close_terminal(item.id)
    else
      M.switch_terminal(item.idx)
      vim.schedule(function()
        M.scroll_to_prompt()
      end)
    end
    return
  end

  if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    vim.schedule(function()
      M.scroll_to_prompt()
    end)
  end
end

function M.scroll_to_prompt()
  if not M.term_win or not vim.api.nvim_win_is_valid(M.term_win) then
    return
  end
  vim.api.nvim_set_current_win(M.term_win)
  vim.wo[M.term_win].virtualedit = "none"

  local cur_buf = vim.api.nvim_win_get_buf(M.term_win)
  local cur_lines = vim.api.nvim_buf_get_lines(cur_buf, 0, -1, false)
  local win_h = vim.api.nvim_win_get_height(M.term_win)

  local last_line = 1
  local last_col = 0
  for idx = #cur_lines, 1, -1 do
    if cur_lines[idx]:match("%S") then
      last_line = idx
      last_col = #cur_lines[idx]
      break
    end
  end

  local max_topline = math.max(1, last_line - win_h + 1)
  local view = vim.api.nvim_win_call(M.term_win, vim.fn.winsaveview)
  view.topline = max_topline
  view.lnum = last_line
  view.col = last_col
  vim.api.nvim_win_call(M.term_win, function()
    vim.fn.winrestview(view)
    pcall(vim.api.nvim_win_set_cursor, M.term_win, { last_line, last_col })
  end)
  vim.cmd("startinsert!")
  vim.api.nvim_echo({}, false, {})
  vim.cmd("silent! echo ''")
end

function M.handle_term_scroll(direction)
  if not M.term_win or not vim.api.nvim_win_is_valid(M.term_win) then
    return
  end

  local cur_buf = vim.api.nvim_win_get_buf(M.term_win)
  local cur_lines = vim.api.nvim_buf_get_lines(cur_buf, 0, -1, false)
  local win_h = vim.api.nvim_win_get_height(M.term_win)

  local last_line = 1
  local last_col = 0
  for idx = #cur_lines, 1, -1 do
    if cur_lines[idx]:match("%S") then
      last_line = idx
      last_col = #cur_lines[idx]
      break
    end
  end

  if last_line <= win_h then
    M.scroll_to_prompt()
    return
  end

  local max_topline = math.max(1, last_line - win_h + 1)
  local view = vim.api.nvim_win_call(M.term_win, vim.fn.winsaveview)
  local step = 3

  if direction == "up" then
    local target_topline = math.max(1, view.topline - step)
    view.topline = target_topline
    view.lnum = math.min(math.max(target_topline, view.lnum), target_topline + win_h - 1)
    vim.cmd("stopinsert")
    vim.api.nvim_win_call(M.term_win, function()
      vim.fn.winrestview(view)
      pcall(vim.api.nvim_win_set_cursor, M.term_win, { view.lnum, view.col })
    end)
  else
    local target_topline = view.topline + step
    if target_topline >= max_topline then
      M.scroll_to_prompt()
    else
      view.topline = target_topline
      view.lnum = math.min(math.max(target_topline, view.lnum), target_topline + win_h - 1)
      vim.cmd("stopinsert")
      vim.api.nvim_win_call(M.term_win, function()
        vim.fn.winrestview(view)
        pcall(vim.api.nvim_win_set_cursor, M.term_win, { view.lnum, view.col })
      end)
    end
  end
end

function M.handle_scroll(direction)
  local mouse = vim.fn.getmousepos()
  if mouse and mouse.winid and mouse.winid > 0 and mouse.winid ~= M.term_win then
    local win = mouse.winid
    if vim.api.nvim_win_is_valid(win) then
      local cmd = (direction == "up") and "3\\<C-y>" or "3\\<C-e>"
      pcall(vim.api.nvim_win_call, win, function()
        vim.cmd("normal! " .. cmd)
      end)
    end
    return
  end

  M.handle_term_scroll(direction)
end

function M.get_or_create_list_buf()
  if M.list_buf and vim.api.nvim_buf_is_valid(M.list_buf) then
    return M.list_buf
  end

  local b = vim.api.nvim_create_buf(false, true)
  vim.bo[b].buftype = "nofile"
  vim.bo[b].bufhidden = "hide"
  vim.bo[b].swapfile = false
  vim.bo[b].filetype = "user_terminal_list"
  vim.b[b].edgy_disable = true
  pcall(vim.api.nvim_buf_set_name, b, "TerminalList")

  local function map(lhs, rhs)
    vim.keymap.set({ "n", "v", "i", "t" }, lhs, rhs, { buffer = b, silent = true })
  end

  map("<LeftMouse>", function()
    local mouse = vim.fn.getmousepos()
    if mouse and mouse.winid == M.list_win then
      M.handle_list_click(mouse)
    end
  end)

  map("<ScrollWheelUp>", function() end)
  map("<ScrollWheelDown>", function() end)
  map("<ScrollWheelLeft>", function() end)
  map("<ScrollWheelRight>", function() end)

  map("<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local item = M.line_map[cursor[1]]
    if item then
      if item.is_plus then
        M.create_terminal()
      elseif item.idx then
        M.switch_terminal(item.idx)
      end
    end
  end)

  map("x", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local item = M.line_map[cursor[1]]
    if item and item.id then
      M.close_terminal(item.id)
    end
  end)

  map("d", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local item = M.line_map[cursor[1]]
    if item and item.id then
      M.close_terminal(item.id)
    end
  end)

  map("+", function()
    M.create_terminal()
  end)

  map("n", function()
    M.create_terminal()
  end)

  map("q", function()
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      M.scroll_to_prompt()
    else
      M.close()
    end
  end)

  map("<Esc>", function()
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      M.scroll_to_prompt()
    end
  end)

  map("<C-`>", function()
    M.toggle()
  end)

  map("<C-~>", function()
    M.toggle()
  end)

  M.list_buf = b
  return b
end

local function ensure_highlights()
  local normal_bg = "#282c34"
  vim.api.nvim_set_hl(0, "UserTermActiveName", { fg = 16777215, bold = true })
  vim.api.nvim_set_hl(0, "UserTermInactiveName", { fg = 8357006 })

  local ok_hl = vim.api.nvim_get_hl(0, { name = "DiagnosticOk" })
  local fg = ok_hl.fg or 10011513
  vim.api.nvim_set_hl(0, "UserTermHeaderPlus", { bg = normal_bg, fg = fg, bold = true })

  vim.api.nvim_set_hl(0, "TermCursor", { bg = "#abb2bf", fg = "#1e222a" })
  vim.api.nvim_set_hl(0, "TermCursorNC", { bg = "#5c6370", fg = "#1e222a" })
  vim.api.nvim_set_hl(0, "UserTerminalNormal", { bg = normal_bg, fg = "#abb2bf" })
end

function M.render_list()
  local b = M.get_or_create_list_buf()
  ensure_highlights()
  M.line_map = {}
  local lines = {}
  local hls = {}

  local h_left = math.floor((M.list_width - 1) / 2)
  local h_right = M.list_width - 1 - h_left
  local plus_str = string.rep(" ", h_left) .. "+" .. string.rep(" ", h_right)
  table.insert(lines, plus_str)
  M.line_map[1] = { is_plus = true, plus_col = h_left + 1 }

  table.insert(lines, string.rep("―", M.list_width))
  M.line_map[2] = { is_sep = true }

  local right_padding = 1
  local right = "x" .. string.rep(" ", right_padding)
  local right_w = vim.fn.strdisplaywidth(right)

  for i, term in ipairs(M.terminals) do
    local is_active = (i == M.current_idx)
    local prefix = is_active and "▸ " or "  "
    local prefix_w = vim.fn.strdisplaywidth(prefix)

    local name = (term.task_name and term.task_name ~= "") and term.task_name or tostring(term.id)

    local max_name_w = math.max(1, M.list_width - prefix_w - right_w - 1)
    if vim.fn.strdisplaywidth(name) > max_name_w then
      local trimmed = name
      while vim.fn.strdisplaywidth(trimmed) > max_name_w - 1 and #trimmed > 0 do
        trimmed = vim.fn.strcharpart(trimmed, 0, vim.fn.strchars(trimmed) - 1)
      end
      name = trimmed .. "…"
    end

    local left = prefix .. name
    local spaces = math.max(1, M.list_width - vim.fn.strdisplaywidth(left) - right_w)
    local row_str = left .. string.rep(" ", spaces) .. right

    table.insert(lines, row_str)
    local lnum = #lines - 1

    M.line_map[#lines] = { id = term.id, idx = i }

    local prefix_len = #prefix
    local name_byte_len = #name
    if is_active then
      table.insert(hls, { lnum = lnum, col_s = 0, col_e = prefix_len, hl = "DiagnosticOk" })
      table.insert(hls, { lnum = lnum, col_s = prefix_len, col_e = prefix_len + name_byte_len, hl = "UserTermActiveName" })
    else
      table.insert(hls, { lnum = lnum, col_s = 0, col_e = prefix_len, hl = "Normal" })
      table.insert(hls, { lnum = lnum, col_s = prefix_len, col_e = prefix_len + name_byte_len, hl = "UserTermInactiveName" })
    end

    local x_byte = string.find(row_str, "x")
    if x_byte then
      table.insert(hls, { lnum = lnum, col_s = x_byte - 1, col_e = x_byte, hl = "DiagnosticError" })
    end
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = b })
  vim.api.nvim_set_option_value("readonly", false, { buf = b })
  vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = b })
  vim.api.nvim_set_option_value("readonly", true, { buf = b })

  vim.api.nvim_buf_clear_namespace(b, NS_ID, 0, -1)

  pcall(vim.api.nvim_buf_add_highlight, b, NS_ID, "UserTermHeaderPlus", 0, h_left, h_left + 1)
  pcall(vim.api.nvim_buf_add_highlight, b, NS_ID, "WinSeparator", 1, 0, -1)

  for _, h in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight, b, NS_ID, h.hl, h.lnum, h.col_s, h.col_e)
  end

  if M.list_win and vim.api.nvim_win_is_valid(M.list_win) then
    vim.wo[M.list_win].winfixwidth = true
    vim.wo[M.list_win].winfixheight = true
    vim.wo[M.list_win].number = false
    vim.wo[M.list_win].relativenumber = false
    vim.wo[M.list_win].signcolumn = "no"
    vim.wo[M.list_win].statuscolumn = ""
    vim.wo[M.list_win].foldcolumn = "0"
    vim.wo[M.list_win].wrap = false
    vim.wo[M.list_win].cursorline = false
    vim.wo[M.list_win].statusline = " "
    vim.wo[M.list_win].winhighlight = "Normal:UserTerminalNormal,NormalNC:UserTerminalNormal,SignColumn:UserTerminalNormal,FoldColumn:UserTerminalNormal,CursorLine:UserTerminalNormal,CursorLineNC:UserTerminalNormal,Cursor:UserTerminalNormal,lCursor:UserTerminalNormal,WinSeparator:WinSeparator"
    pcall(vim.api.nvim_win_set_width, M.list_win, M.list_width)
  end
end

local function enforce_list_width()
  if M.list_win and vim.api.nvim_win_is_valid(M.list_win) then
    local target_w = get_target_list_width()
    local width_changed = (target_w ~= M.list_width)
    M.list_width = target_w

    vim.wo[M.list_win].winfixwidth = true
    vim.wo[M.list_win].winfixheight = true
    vim.wo[M.list_win].number = false
    vim.wo[M.list_win].relativenumber = false
    vim.wo[M.list_win].signcolumn = "no"
    vim.wo[M.list_win].statuscolumn = ""
    vim.wo[M.list_win].foldcolumn = "0"
    vim.wo[M.list_win].wrap = false
    vim.wo[M.list_win].cursorline = false
    vim.wo[M.list_win].statusline = " "
    vim.wo[M.list_win].winhighlight = "Normal:UserTerminalNormal,NormalNC:UserTerminalNormal,SignColumn:UserTerminalNormal,FoldColumn:UserTerminalNormal,CursorLine:UserTerminalNormal,CursorLineNC:UserTerminalNormal,Cursor:UserTerminalNormal,lCursor:UserTerminalNormal,WinSeparator:WinSeparator"
    local cur_w = vim.api.nvim_win_get_width(M.list_win)
    if cur_w ~= M.list_width then
      pcall(vim.api.nvim_win_set_width, M.list_win, M.list_width)
    end
    if width_changed and M.is_open() then
      M.render_list()
    end
  end
end

function M.create_terminal(opts)
  opts = opts or {}
  local next_id = 1
  for _, t in ipairs(M.terminals) do
    if t.id >= next_id then
      next_id = t.id + 1
    end
  end

  local term_name = opts.name or tostring(next_id)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  vim.b[buf].edgy_disable = true

  local term_obj = {
    id = next_id,
    buf = buf,
    chan = nil,
    name = term_name,
    task_name = opts.task_name,
  }

  table.insert(M.terminals, term_obj)
  M.current_idx = #M.terminals

  local shell = vim.o.shell ~= "" and vim.o.shell or "/bin/bash"

  vim.api.nvim_buf_call(buf, function()
    local chan = vim.fn.termopen(shell, {
      on_exit = function(_, exit_code)
        M.on_terminal_exit(term_obj, exit_code)
      end,
    })
    term_obj.chan = chan
  end)

  vim.keymap.set({ "n", "t" }, "<LeftMouse>", function()
    local mouse = vim.fn.getmousepos()
    if not mouse or not mouse.winid or mouse.winid <= 0 then
      return
    end

    if mouse.winid == M.term_win then
      M.scroll_to_prompt()
    elseif mouse.winid == M.list_win then
      M.handle_list_click(mouse)
    else
      vim.cmd("stopinsert")
      vim.api.nvim_set_current_win(mouse.winid)
      if mouse.line > 0 then
        pcall(vim.api.nvim_win_set_cursor, mouse.winid, { mouse.line, math.max(0, mouse.column - 1) })
      end
    end
  end, { buffer = buf, silent = true })

  vim.keymap.set({ "n", "t" }, "<2-LeftMouse>", function()
    local mouse = vim.fn.getmousepos()
    if mouse and mouse.winid == M.term_win then
      M.scroll_to_prompt()
    end
  end, { buffer = buf, silent = true })

  vim.keymap.set({ "n", "t" }, "<3-LeftMouse>", function()
    local mouse = vim.fn.getmousepos()
    if mouse and mouse.winid == M.term_win then
      M.scroll_to_prompt()
    end
  end, { buffer = buf, silent = true })

  vim.keymap.set({ "n", "t" }, "<ScrollWheelUp>", function()
    M.handle_scroll("up")
  end, { buffer = buf, silent = true })

  vim.keymap.set({ "n", "t" }, "<ScrollWheelDown>", function()
    M.handle_scroll("down")
  end, { buffer = buf, silent = true })

  vim.keymap.set({ "n", "t" }, "<ScrollWheelLeft>", function() end, { buffer = buf, silent = true })
  vim.keymap.set({ "n", "t" }, "<ScrollWheelRight>", function() end, { buffer = buf, silent = true })
  vim.keymap.set({ "n", "t" }, "<S-ScrollWheelUp>", function()
    M.handle_scroll("up")
  end, { buffer = buf, silent = true })
  vim.keymap.set({ "n", "t" }, "<S-ScrollWheelDown>", function()
    M.handle_scroll("down")
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "i", function()
    M.scroll_to_prompt()
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "a", function()
    M.scroll_to_prompt()
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<CR>", function()
    M.scroll_to_prompt()
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "G", function()
    M.scroll_to_prompt()
  end, { buffer = buf, silent = true })

  if opts.cmd and opts.cmd ~= "" then
    if opts.task_name then
      M.task_statuses[opts.task_name] = "RUNNING"
    end

    local uv = vim.uv or vim.loop
    local cmd_sent = false
    local start_timer = uv.new_timer()
    local start_ticks = 0

    local function send_clean_cmd()
      if cmd_sent then return end
      cmd_sent = true
      if start_timer and not start_timer:is_closing() then
        start_timer:stop()
        start_timer:close()
      end

      vim.api.nvim_chan_send(term_obj.chan, opts.cmd .. "\n")

      if opts.task_name then
        local monitor_timer = uv.new_timer()
        local sent_ticks = 0
        monitor_timer:start(
          200,
          200,
          vim.schedule_wrap(function()
            sent_ticks = sent_ticks + 1
            if not vim.api.nvim_buf_is_valid(buf) then
              M.task_statuses[opts.task_name] = "CANCELED"
              monitor_timer:stop()
              if not monitor_timer:is_closing() then monitor_timer:close() end
              pcall(function() require("plugins.modules.tasks").render() end)
              return
            end

            local pid = vim.fn.jobpid(term_obj.chan)
            local has_children = false
            if pid and pid > 0 then
              local p_path = string.format("/proc/%d/task/%d/children", pid, pid)
              local f = io.open(p_path, "r")
              if f then
                local c = f:read("*all") or ""
                f:close()
                if c:match("%S") then
                  has_children = true
                end
              end
            end

            if has_children then
              if M.task_statuses[opts.task_name] ~= "RUNNING" then
                M.task_statuses[opts.task_name] = "RUNNING"
                pcall(function() require("plugins.modules.tasks").render() end)
              end
              return
            end

            if sent_ticks >= 3 then
              local cur_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
              local has_end_prompt = false
              for i = #cur_lines, math.max(1, #cur_lines - 3), -1 do
                if cur_lines[i]:match("[$%%#]%s*$") then
                  has_end_prompt = true
                  break
                end
              end

              if has_end_prompt then
                local output_text = table.concat(cur_lines, "\n"):lower()
                local is_failure = false
                local error_patterns = {
                  "error:",
                  "failed",
                  "command not found",
                  "no such file or directory",
                  "unchecked dependencies",
                  "compilation failed",
                  "syntaxerror",
                  "%*%* %(exit%)",
                  "%*%* %(compileerror%)",
                  "1 error",
                  "fatal:",
                }
                for _, pat in ipairs(error_patterns) do
                  if output_text:find(pat) then
                    is_failure = true
                    break
                  end
                end

                M.task_statuses[opts.task_name] = is_failure and "FAILURE" or "SUCCESS"
                monitor_timer:stop()
                if not monitor_timer:is_closing() then monitor_timer:close() end
                pcall(function() require("plugins.modules.tasks").render() end)
              end
            end
          end)
        )
      end
    end

    local function check_prompt_and_send()
      if cmd_sent then return end
      if not vim.api.nvim_buf_is_valid(buf) then return end
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for _, l in ipairs(lines) do
        if l:match("[$%%#]%s*$") or l:match("[$%%#]%s+") then
          send_clean_cmd()
          return
        end
      end
    end

    vim.api.nvim_buf_attach(buf, false, {
      on_lines = function()
        vim.schedule(check_prompt_and_send)
      end,
    })

    start_timer:start(
      30,
      30,
      vim.schedule_wrap(function()
        start_ticks = start_ticks + 1
        if cmd_sent or not vim.api.nvim_buf_is_valid(buf) then
          if not start_timer:is_closing() then
            start_timer:stop()
            start_timer:close()
          end
          return
        end
        check_prompt_and_send()
        if not cmd_sent and start_ticks >= 100 then
          send_clean_cmd()
        end
      end)
    )
  end

  local uv = vim.uv or vim.loop
  local prompt_timer = uv.new_timer()
  local prompt_ticks = 0
  prompt_timer:start(
    20,
    20,
    vim.schedule_wrap(function()
      prompt_ticks = prompt_ticks + 1
      if not vim.api.nvim_buf_is_valid(buf) or prompt_ticks > 50 then
        prompt_timer:stop()
        if not prompt_timer:is_closing() then
          prompt_timer:close()
        end
        return
      end

      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for idx = #lines, 1, -1 do
        if lines[idx]:match("%S") then
          prompt_timer:stop()
          if not prompt_timer:is_closing() then
            prompt_timer:close()
          end
          if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
            local cur_buf = vim.api.nvim_win_get_buf(M.term_win)
            if cur_buf == buf then
              M.scroll_to_prompt()
            end
          end
          break
        end
      end
    end)
  )

  if M.is_open() then
    M.switch_terminal(M.current_idx)
  else
    M.open()
  end
  M.render_list()
  return term_obj
end

function M.on_terminal_exit(term_obj, exit_code)
  if term_obj.closing then
    return
  end

  local idx = nil
  for i, t in ipairs(M.terminals) do
    if t.id == term_obj.id then
      idx = i
      break
    end
  end
  if not idx then
    return
  end

  if term_obj.task_name and M.task_statuses[term_obj.task_name] == "RUNNING" then
    M.task_statuses[term_obj.task_name] = (exit_code == 0 and "SUCCESS" or "FAILURE")
    pcall(function()
      require("plugins.modules.tasks").render()
    end)
  end

  local term = M.terminals[idx]

  if #M.terminals == 1 then
    table.remove(M.terminals, 1)
    M.current_idx = 1
    M.close()
    if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
      pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
    end
    return
  end

  local was_active = (idx == M.current_idx)

  if was_active and M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    local target_prev_idx = (idx > 1) and (idx - 1) or (idx + 1)
    local prev_term = M.terminals[target_prev_idx]
    if prev_term and prev_term.buf and vim.api.nvim_buf_is_valid(prev_term.buf) then
      vim.api.nvim_win_set_buf(M.term_win, prev_term.buf)
      M.update_winbar(prev_term)
    end
  end

  table.remove(M.terminals, idx)

  if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
    pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
  end

  if was_active then
    if idx > 1 then
      M.current_idx = idx - 1
    else
      M.current_idx = 1
    end
  else
    if idx < M.current_idx then
      M.current_idx = M.current_idx - 1
    end
    if M.current_idx > #M.terminals then
      M.current_idx = #M.terminals
    end
  end

  if M.is_open() then
    local active = M.get_active_terminal()
    if active and M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      vim.api.nvim_win_set_buf(M.term_win, active.buf)
      M.update_winbar(active)
      M.scroll_to_prompt()
    end
    M.render_list()
  end
end

function M.close_terminal(id)
  local idx = nil
  for i, t in ipairs(M.terminals) do
    if t.id == id then
      idx = i
      break
    end
  end
  if not idx then
    return
  end

  local term = M.terminals[idx]
  term.closing = true
  if term.chan then
    pcall(vim.fn.jobstop, term.chan)
  end
  if term.task_name and M.task_statuses[term.task_name] == "RUNNING" then
    M.task_statuses[term.task_name] = "CANCELED"
    pcall(function()
      require("plugins.modules.tasks").render()
    end)
  end

  if #M.terminals == 1 then
    table.remove(M.terminals, 1)
    M.current_idx = 1
    M.close()
    if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
      pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
    end
    return
  end

  local was_active = (idx == M.current_idx)

  if was_active and M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    local target_prev_idx = (idx > 1) and (idx - 1) or (idx + 1)
    local prev_term = M.terminals[target_prev_idx]
    if prev_term and prev_term.buf and vim.api.nvim_buf_is_valid(prev_term.buf) then
      vim.api.nvim_win_set_buf(M.term_win, prev_term.buf)
      M.update_winbar(prev_term)
    end
  end

  table.remove(M.terminals, idx)

  if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
    pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
  end

  if was_active then
    if idx > 1 then
      M.current_idx = idx - 1
    else
      M.current_idx = 1
    end
  else
    if idx < M.current_idx then
      M.current_idx = M.current_idx - 1
    end
    if M.current_idx > #M.terminals then
      M.current_idx = #M.terminals
    end
  end

  if M.is_open() then
    local active = M.get_active_terminal()
    if active and M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      vim.api.nvim_win_set_buf(M.term_win, active.buf)
      M.update_winbar(active)
      M.scroll_to_prompt()
    end
    M.render_list()
  end
end

function M.switch_terminal(idx)
  if idx < 1 or idx > #M.terminals then
    return
  end
  M.current_idx = idx
  local active = M.terminals[idx]
  if M.is_open() and active then
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      vim.api.nvim_win_set_buf(M.term_win, active.buf)
      M.update_winbar(active)
      M.scroll_to_prompt()
    end
    M.render_list()
  end
end

function M.focus()
  if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    M.scroll_to_prompt()
  end
end

function M.open()
  if M.is_open() then
    M.focus()
    return
  end

  if #M.terminals == 0 then
    M.create_terminal()
    return
  end

  local active = M.get_active_terminal()
  if not active then
    M.create_terminal()
    return
  end

  local target_h = get_target_height()
  M.height = target_h
  vim.cmd("botright " .. tostring(target_h) .. "split")
  local term_win = vim.api.nvim_get_current_win()
  M.term_win = term_win

  vim.api.nvim_win_set_buf(term_win, active.buf)
  vim.wo[term_win].number = false
  vim.wo[term_win].relativenumber = false
  vim.wo[term_win].signcolumn = "no"
  vim.wo[term_win].statuscolumn = ""
  vim.wo[term_win].foldcolumn = "0"
  vim.wo[term_win].winbar = ""
  vim.wo[term_win].cursorline = false
  vim.wo[term_win].winfixheight = true
  vim.wo[term_win].virtualedit = "none"
  vim.wo[term_win].winhighlight = "Normal:UserTerminalNormal,NormalNC:UserTerminalNormal,SignColumn:UserTerminalNormal,CursorLine:UserTerminalNormal,CursorLineNC:UserTerminalNormal,WinSeparator:WinSeparator"
  vim.w[term_win].edgy_disable = true

  if package.loaded["edgy"] then
    local cfg = require("edgy.config")
    if cfg.layout and cfg.layout.left and cfg.layout.left.wins then
      for _, w in ipairs(cfg.layout.left.wins) do
        if w:is_valid() then
          vim.api.nvim_win_call(w.win, function()
            vim.cmd("wincmd H")
          end)
          local cur_w = type(cfg.layout.left.size) == "function" and cfg.layout.left.size() or cfg.layout.left.size
          pcall(vim.api.nvim_win_set_width, w.win, cur_w or 24)
        end
      end
    end
  end

  M.list_width = get_target_list_width()
  local lbuf = M.get_or_create_list_buf()
  local list_win = vim.api.nvim_open_win(lbuf, false, {
    win = term_win,
    split = "right",
    width = M.list_width,
  })
  M.list_win = list_win

  vim.wo[list_win].number = false
  vim.wo[list_win].relativenumber = false
  vim.wo[list_win].signcolumn = "no"
  vim.wo[list_win].statuscolumn = ""
  vim.wo[list_win].foldcolumn = "0"
  vim.wo[list_win].wrap = false
  vim.wo[list_win].cursorline = false
  vim.wo[list_win].winfixwidth = true
  vim.wo[list_win].winfixheight = true
  vim.wo[list_win].winbar = ""
  vim.wo[list_win].statusline = " "
  vim.wo[list_win].winhighlight = "Normal:UserTerminalNormal,NormalNC:UserTerminalNormal,SignColumn:UserTerminalNormal,FoldColumn:UserTerminalNormal,CursorLine:UserTerminalNormal,CursorLineNC:UserTerminalNormal,Cursor:UserTerminalNormal,lCursor:UserTerminalNormal,WinSeparator:WinSeparator"
  vim.w[list_win].edgy_disable = true
  vim.api.nvim_win_set_width(list_win, M.list_width)

  M.update_winbar(active)
  M.render_list()

  M.scroll_to_prompt()
end

function M.close()
  if M.list_win and vim.api.nvim_win_is_valid(M.list_win) then
    local lw = M.list_win
    M.list_win = nil
    pcall(vim.api.nvim_win_close, lw, true)
  end
  if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    local tw = M.term_win
    M.term_win = nil
    pcall(vim.api.nvim_win_close, tw, true)
  end

  if package.loaded["edgy"] then
    pcall(require("edgy.editor").goto_main)
  end
end

function M.toggle()
  if M.is_open() then
    local cur_win = vim.api.nvim_get_current_win()
    if cur_win == M.term_win or cur_win == M.list_win then
      M.close()
    else
      M.focus()
    end
  else
    M.open()
  end
end

function M.run_task(task_item)
  if not task_item then
    return
  end
  local term = M.create_terminal({
    name = task_item.name,
    task_name = task_item.name,
    cmd = task_item.command,
  })
  return term
end

local augroup = vim.api.nvim_create_augroup("UserTerminalLayoutSync", { clear = true })

vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function()
    M.list_width = get_target_list_width()
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      local target_h = get_target_height()
      pcall(vim.api.nvim_win_set_height, M.term_win, target_h)
      M.height = target_h
    end
    M.last_screen_lines = vim.o.lines
    enforce_list_width()
    vim.schedule(function()
      enforce_list_width()
      if M.is_open() then
        M.render_list()
      end
    end)
  end,
})

vim.api.nvim_create_autocmd({ "WinResized", "BufEnter", "WinEnter" }, {
  group = augroup,
  callback = function()
    enforce_list_width()
    vim.schedule(function()
      enforce_list_width()
    end)
    if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
      local cur_h = vim.api.nvim_win_get_height(M.term_win)
      if vim.o.lines == M.last_screen_lines and cur_h >= 3 and vim.o.lines > 0 then
        M.height_ratio = cur_h / vim.o.lines
        M.height = cur_h
      end
      if vim.api.nvim_get_current_win() == M.term_win then
        local cur_buf = vim.api.nvim_get_current_buf()
        if vim.bo[cur_buf].buftype == "terminal" then
          M.scroll_to_prompt()
        end
      end
    end
  end,
})

vim.api.nvim_create_autocmd("WinClosed", {
  group = augroup,
  callback = function(args)
    local closed_win = tonumber(args.match)
    if closed_win == M.term_win then
      M.term_win = nil
      if M.list_win and vim.api.nvim_win_is_valid(M.list_win) then
        local lw = M.list_win
        M.list_win = nil
        pcall(vim.api.nvim_win_close, lw, true)
      end
    elseif closed_win == M.list_win then
      M.list_win = nil
      if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
        local tw = M.term_win
        M.term_win = nil
        pcall(vim.api.nvim_win_close, tw, true)
      end
    end
  end,
})

package.loaded["plugins.modules.terminal"] = M
package.loaded["plugins.terminal"] = M
package.loaded["user.terminal"] = M
package.loaded["user.plugins.terminal"] = M
package.loaded["user.modules.terminal"] = M
return M
