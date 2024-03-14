vim.cmd("set nu")
vim.cmd("set encoding=utf-8")
vim.cmd("set ignorecase")

vim.cmd("set nobackup")
vim.cmd("set noswapfile")
vim.cmd("set nowritebackup")
vim.cmd("set noundofile")

vim.cmd("set ts=2")
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set autoindent")

-- 补全上下选择
vim.cmd('cnoremap <Up> <C-p>')
vim.cmd('cnoremap <Down> <C-n>')