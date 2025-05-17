vim.cmd([[
  cmap <Down> <C-n>
  cmap <Up> <C-p>
]])

-- 编辑
vim.keymap.set({'n', 'v'}, '<C-c>', '"+y', { noremap = true, desc = "复制" })
vim.keymap.set({'n', 'v', 'i'}, '<C-v>', '"+p', { noremap = true, desc = "粘贴" })
vim.keymap.set('v', '<C-x>', '"+d', { noremap = true, desc = "剪切" })

-- 撤销
vim.keymap.set({'n', 'v'}, '<C-z>', 'u', { noremap = true, desc = "撤销" })
vim.keymap.set({'n', 'v'}, '<C-y>', '<C-r>', { noremap = true, desc = "重做" })

-- 前进后退
vim.keymap.set('n', '<A-,>', '<C-o>', { noremap = true, desc = "上一个位置" })
vim.keymap.set('n', '<A-.>', '<C-i>', { noremap = true, desc = "下一个位置" })