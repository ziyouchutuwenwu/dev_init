vim.cmd([[
  cmap <Down> <C-n>
  cmap <Up> <C-p>
]])

vim.keymap.set('n', '<C-c>', '"+yy', { noremap = true, desc = "复制当前行到系统剪贴板" })
vim.keymap.set('v', '<C-c>', '"+y', { noremap = true, desc = "复制到系统剪贴板" })
vim.keymap.set('n', '<C-x>', '"+dd', { noremap = true, desc = "剪切当前行到系统剪贴板" })
vim.keymap.set('v', '<C-x>', '"+d', { noremap = true, desc = "剪切到系统剪贴板" })

local function do_paste()
  local text = vim.fn.getreg('+')
  if text == '' then
    vim.notify('系统剪贴板为空', vim.log.levels.WARN)
    return
  end
  local mode = vim.fn.mode()
  if mode == 'c' then
    vim.fn.setcmdline(vim.fn.getcmdline() .. text)
    vim.fn.setcmdpos(vim.fn.getcmdpos() + #text)
  else
    vim.api.nvim_paste(text, false, -1)
  end
end

vim.keymap.set({'i', 'c', 'n'}, '<C-v>', do_paste, { noremap = true, desc = "平滑粘贴系统剪贴板" })

vim.keymap.set('v', '<C-v>', function()
  vim.cmd('normal! "_d')
  do_paste()
end, { noremap = true, desc = "替换粘贴系统剪贴板" })

vim.keymap.set({'n', 'v', 'i', 'c'}, '<C-z>', function()
  if vim.fn.mode() == 'i' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>uli', true, false, true), 'n', false)
  elseif vim.fn.mode() == 'c' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>u', true, false, true), 'n', false)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('u', true, false, true), 'n', false)
  end
end, { noremap = true, desc = "撤销" })
vim.keymap.set({'n', 'v'}, '<C-y>', '<C-r>', { noremap = true, desc = "重做" })

vim.keymap.set('n', '<M-Left>', '<C-o>', { noremap = true, desc = "跳转返回 (向后)" })
vim.keymap.set('n', '<M-Right>', '<C-i>', { noremap = true, desc = "跳转前进" })
vim.keymap.set({ 'v', 'i' }, '<M-Left>', '<Esc><C-o>', { noremap = true, desc = "跳转返回 (向后)" })
vim.keymap.set({ 'v', 'i' }, '<M-Right>', '<Esc><C-i>', { noremap = true, desc = "跳转前进" })
vim.keymap.set('n', '<M-,>', '<C-o>', { noremap = true, desc = "上一个位置 (返回)" })
vim.keymap.set('n', '<M-.>', '<C-i>', { noremap = true, desc = "下一个位置 (前进)" })

vim.keymap.set('n', '<C-LeftMouse>', '<LeftMouse><Cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, desc = "跳转到定义 (Ctrl+单击)" })
vim.keymap.set({ 'v', 'i' }, '<C-LeftMouse>', '<Esc><LeftMouse><Cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, desc = "跳转到定义 (Ctrl+单击)" })

vim.keymap.set({ 'n', 'v' }, '<Leader>lf', function()
  require("snacks").picker.lines()
end, { noremap = true, desc = "当前文件搜索 (Local Find)" })

vim.keymap.set({ 'n', 'v' }, '<Leader>gf', function()
  require("snacks").picker.grep()
end, { noremap = true, desc = "全局搜索 (Global Find)" })

vim.keymap.set({ 'n', 'v', 'x', 'i' }, '<C-a>', '<Esc>ggVG', { noremap = true, desc = "全选" })

vim.keymap.set({'n', 'v'}, '<C-s>', ':w<CR>', { noremap = true, desc = "保存" })
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>a', { noremap = true, desc = "保存" })

vim.keymap.set('n', '<M-Up>', '<Cmd>move .-2<CR>==', { noremap = true, desc = "向上移动当前行" })
vim.keymap.set('n', '<M-Down>', '<Cmd>move .+1<CR>==', { noremap = true, desc = "向下移动当前行" })
vim.keymap.set('v', '<M-Up>', ":move '<-2<CR>gv=gv", { noremap = true, desc = "向上移动选中行" })
vim.keymap.set('v', '<M-Down>', ":move '>+1<CR>gv=gv", { noremap = true, desc = "向下移动选中行" })

vim.keymap.set('v', '<BS>', function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.fn.getline(start_line, end_line)
  if type(lines) == "string" then
    lines = { lines }
  end
  local all_empty = true
  for _, line in ipairs(lines) do
    if line:match("%S") then
      all_empty = false
      break
    end
  end
  if all_empty then
    vim.api.nvim_feedkeys('dd', 'n', false)
  else
    vim.api.nvim_feedkeys('d', 'n', false)
  end
end, { noremap = true, desc = "可视模式下退格键删除（支持空行）" })

local function close_other_buffers()
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  local keep_buf = nil

  if vim.bo[cur_buf].buftype == "" and vim.bo[cur_buf].buflisted then
    keep_buf = cur_buf
  else

    if package.loaded["edgy"] then
      local main_wins = require("edgy.editor").list_wins().main
      for win, _ in pairs(main_wins) do
        if vim.api.nvim_win_is_valid(win) then
          local b = vim.api.nvim_win_get_buf(win)
          if vim.bo[b].buftype == "" and vim.bo[b].buflisted then
            keep_buf = b
            break
          end
        end
      end
    end

    if not keep_buf then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local b = vim.api.nvim_win_get_buf(win)
        if vim.bo[b].buftype == "" and vim.bo[b].buflisted then
          keep_buf = b
          break
        end
      end
    end
  end

  if not keep_buf then
    vim.notify("未找到可保留的主编辑文件", vim.log.levels.WARN)
    return
  end

  local closed_count = 0
  local skipped_modified = 0
  local abuf = require("astrocore.buffer")

  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted and vim.bo[b].buftype == "" then
      if b ~= keep_buf then
        if vim.bo[b].modified then
          skipped_modified = skipped_modified + 1
        else
          abuf.close(b, false)
          closed_count = closed_count + 1
        end
      end
    end
  end

  local keep_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(keep_buf), ":t")
  if keep_name == "" then keep_name = "[未命名]" end

  if closed_count > 0 then
    local msg = string.format("已关闭 %d 个其他文件，保留: %s", closed_count, keep_name)
    if skipped_modified > 0 then
      msg = msg .. string.format(" (%d 个未保存文件已跳过)", skipped_modified)
    end
    vim.notify(msg, vim.log.levels.INFO)
  else
    if skipped_modified > 0 then
      vim.notify(string.format("其他 %d 个文件有未保存的修改，已跳过", skipped_modified), vim.log.levels.WARN)
    else
      vim.notify("没有其他文件需要关闭", vim.log.levels.INFO)
    end
  end
end

vim.keymap.set('n', '<Leader>co', close_other_buffers, { noremap = true, desc = "关闭其他文件 (Close Others)" })
