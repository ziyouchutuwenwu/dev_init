vim.cmd([[
  cmap <Down> <C-n>
  cmap <Up> <C-p>
]])

vim.keymap.set({'n', 'v'}, '<C-c>', '"+y', { noremap = true, desc = "复制" })
vim.keymap.set({'n', 'v', 'i'}, '<C-v>', '"+p', { noremap = true, desc = "粘贴" })
vim.keymap.set('v', '<C-x>', '"+d', { noremap = true, desc = "剪切" })

-- C-z = u
vim.keymap.set({'n', 'v'}, '<C-z>', 'u', { noremap = true, desc = "撤销" })

-- C-y = ctrl-r
vim.keymap.set({'n', 'v'}, '<C-y>', '<C-r>', { noremap = true, desc = "重做" })