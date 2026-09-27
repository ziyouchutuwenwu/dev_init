-- 命令行历史导航
vim.cmd([[
  cmap <Down> <C-n>
  cmap <Up> <C-p>
]])

-- 复制粘贴（系统剪贴板通道：与外部世界无缝交互）
-- Normal 模式复制/剪切当前整行；Visual 模式复制/剪切选中内容
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

-- i, c, n 模式统一使用平滑光标处粘贴系统剪贴板（不跳行、不截断）
vim.keymap.set({'i', 'c', 'n'}, '<C-v>', do_paste, { noremap = true, desc = "平滑粘贴系统剪贴板" })
-- visual 模式替换粘贴时使用黑洞寄存器，不污染任何剪贴板
vim.keymap.set('v', '<C-v>', function()
  vim.cmd('normal! "_d')
  do_paste()
end, { noremap = true, desc = "替换粘贴系统剪贴板" })

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

-- 全选（普通模式、插入模式、可视模式下按 Ctrl+a 均一键全选所有行）
vim.keymap.set({ 'n', 'v', 'x', 'i' }, '<C-a>', '<Esc>ggVG', { noremap = true, desc = "全选" })

-- 保存（注意：<C-s> 在终端中默认是 XON 流控制，需在终端配置中取消该绑定）
vim.keymap.set({'n', 'v'}, '<C-s>', ':w<CR>', { noremap = true, desc = "保存" })
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>a', { noremap = true, desc = "保存" })

-- 整行移动（使用 :move 命令，绝对不污染剪贴板）
vim.keymap.set('n', '<M-Up>', '<Cmd>move .-2<CR>==', { noremap = true, desc = "向上移动当前行" })
vim.keymap.set('n', '<M-Down>', '<Cmd>move .+1<CR>==', { noremap = true, desc = "向下移动当前行" })
vim.keymap.set('v', '<M-Up>', ":move '<-2<CR>gv=gv", { noremap = true, desc = "向上移动选中行" })
vim.keymap.set('v', '<M-Down>', ":move '>+1<CR>gv=gv", { noremap = true, desc = "向下移动选中行" })

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
