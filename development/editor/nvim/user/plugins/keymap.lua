-- 命令行历史导航
vim.cmd([[
  cmap <Down> <C-n>
  cmap <Up> <C-p>
]])

-- 复制粘贴
vim.keymap.set({'n', 'v'}, '<C-c>', '"+y', { noremap = true, desc = "复制" })
vim.keymap.set('v', '<C-x>', '"+d', { noremap = true, desc = "剪切" })

vim.keymap.set({'n', 'v', 'i', 'c'}, '<C-v>', function()
  local mode = vim.fn.mode()
  if vim.fn.getreg('+') == '' then
    vim.notify('剪贴板为空', vim.log.levels.WARN)
    return
  end
  if mode == 'i' then
    local text = vim.fn.getreg('+')
    vim.api.nvim_paste(text, false, -1)
  elseif mode == 'c' then
    local text = vim.fn.getreg('+')
    vim.fn.setcmdline(vim.fn.getcmdline() .. text)
    vim.fn.setcmdpos(vim.fn.getcmdpos() + #text)
  elseif mode == 'v' or mode == 'V' or mode == '\22' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>"+p', true, false, true), 'n', false)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('"+p', true, false, true), 'n', false)
  end
end, { noremap = true, desc = "粘贴" })

-- 撤销重做
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

-- 跳转导航
vim.keymap.set('n', '<M-,>', '<C-o>', { noremap = true, desc = "上一个位置" })
vim.keymap.set('n', '<M-.>', '<C-i>', { noremap = true, desc = "下一个位置" })

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

-- 整行移动
vim.keymap.set('n', '<M-Up>', 'ddkP', { noremap = true, desc = "向上移动当前行" })
vim.keymap.set('n', '<M-Down>', 'ddp', { noremap = true, desc = "向下移动当前行" })
vim.keymap.set('v', '<M-Up>', ":move '<-2<CR>gv", { noremap = true, desc = "向上移动选中行" })
vim.keymap.set('v', '<M-Down>', ":move '>+1<CR>gv", { noremap = true, desc = "向下移动选中行" })

-- 智能删除
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
