return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    local status = require("astroui.status")
    local sidebar_fts = {
      ["neo-tree"] = true,
      ["aerial"] = true,
      ["overseer_tasks"] = true,
      ["OverseerList"] = true,
      ["edgy"] = true,
      ["user_terminal_list"] = true,
      ["user_terminal_plus"] = true,
    }

    local function is_editor_buf(buf)
      if not buf or not vim.api.nvim_buf_is_valid(buf) then return false end
      local bt = vim.bo[buf].buftype
      local ft = vim.bo[buf].filetype
      if sidebar_fts[ft] then return false end
      if bt == "nofile" or bt == "prompt" or bt == "quickfix" then return false end
      return true
    end

    local function get_active_editor()
      local cur_win = vim.api.nvim_get_current_win()
      local cur_buf = vim.api.nvim_win_get_buf(cur_win)
      if is_editor_buf(cur_buf) then
        _G._last_editor_win = cur_win
        _G._last_editor_buf = cur_buf
        return cur_win, cur_buf
      end

      if _G._last_editor_win
        and vim.api.nvim_win_is_valid(_G._last_editor_win)
        and _G._last_editor_buf
        and vim.api.nvim_buf_is_valid(_G._last_editor_buf)
        and is_editor_buf(_G._last_editor_buf)
      then
        return _G._last_editor_win, _G._last_editor_buf
      end

      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if is_editor_buf(buf) then
          _G._last_editor_win = win
          _G._last_editor_buf = buf
          return win, buf
        end
      end

      return cur_win, cur_buf
    end

    local time_component = {
      provider = function()
        return " " .. os.date("%Y-%m-%d %H:%M:%S") .. " "
      end,
      hl = { fg = "fg" },
    }

    -- 将时间组件加到状态栏右端
    table.insert(opts.statusline, time_component)

    -- 启动 1s 定时器刷新状态栏秒级时间
    if not _G._statusline_timer then
      local timer = (vim.uv or vim.loop).new_timer()
      _G._statusline_timer = timer
      timer:start(1000, 1000, vim.schedule_wrap(function()
        pcall(vim.cmd.redrawstatus)
      end))

      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          if _G._statusline_timer and not _G._statusline_timer:is_closing() then
            _G._statusline_timer:stop()
            _G._statusline_timer:close()
            _G._statusline_timer = nil
          end
        end,
      })
    end

    -- 保持原状态栏完整内容：当切换焦点至侧边栏(Alt+1/2/3)时，保持主编辑文件的状态栏不变
    local orig_statusline = opts.statusline
    opts.statusline = {
      hl = { fg = "fg", bg = "bg" },
      init = function(self)
        local win, buf = get_active_editor()
        self.winid = win
        self.bufnr = buf
      end,
      orig_statusline,
    }
    opts.winbar = nil
    return opts
  end,
}
