vim.cmd([[
  cmap <Down> <C-n>
  cmap <Up> <C-p>
]])


-- 编辑
vim.keymap.set({'n', 'v'}, '<C-c>', '"+y', { noremap = true, desc = "复制" })
vim.keymap.set('v', '<C-x>', '"+d', { noremap = true, desc = "剪切" })


-- 粘贴
vim.keymap.set({'n', 'v', 'i', 'c'}, '<C-v>', function()
  if vim.fn.mode() == 'i' then
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local text = vim.fn.getreg('+')
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>"+pi', true, false, true), 'n', false)
    vim.schedule(function()
      vim.api.nvim_win_set_cursor(0, {row, col + #text})
    end)
  elseif vim.fn.mode() == 'c' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>"+p', true, false, true), 'n', false)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('"+p', true, false, true), 'n', false)
  end
end, { noremap = true, desc = "粘贴" })


-- 撤销
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


-- 前进后退
vim.keymap.set('n', '<A-,>', '<C-o>', { noremap = true, desc = "上一个位置" })
vim.keymap.set('n', '<A-.>', '<C-i>', { noremap = true, desc = "下一个位置" })


-- 全选
vim.keymap.set({'n', 'v', 'i', 'c'}, '<C-a>', function()
  if vim.fn.mode() == 'i' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>ggVGi', true, false, true), 'n', false)
  elseif vim.fn.mode() == 'c' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>ggVG', true, false, true), 'n', false)
  elseif vim.fn.mode() == 'v' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>ggVG', true, false, true), 'n', false)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('ggVG', true, false, true), 'n', false)
  end
end, { noremap = true, desc = "全选" })


-- 保存
vim.keymap.set({'n', 'v'}, '<C-s>', ':w<CR>', { noremap = true, desc = "保存" })
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>a', { noremap = true, desc = "保存" })


-- 退格键删除
vim.keymap.set('v', '<BS>', function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.fn.getline(start_line, end_line)
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