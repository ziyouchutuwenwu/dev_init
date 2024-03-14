local map = vim.api.nvim_set_keymap
local opt = { noremap = true, silent = true }

-- 分屏
map("n", "sh", ":vsp<CR>", opt)
map("n", "sv", ":sp<CR>", opt)

-- 新建标签
vim.cmd('noremap <C-t> <CMD>tabnew<CR>')
vim.cmd('inoremap <C-t> <CMD>tabnew<CR>')

-- 全选
map("n", "<C-a>", "ggVG", opt)
map("i", "<C-a>", "<Esc>ggVG", opt)

-- 复制
vim.cmd('vnoremap <C-c> y:call system("xclip -selection c", @")<CR>')

-- 粘贴
map("n", "<C-v>", '"+p', opt)
map("i", "<C-v>", '<Esc>"+pa', opt)

-- 剪切
vim.cmd('vnoremap <C-x> "+x')

-- 保存
map("n", "<C-s>", "<CMD>update<CR>", opt)
map("i", "<C-s>", '<CMD>update<CR>', opt)

-- 文件浏览器
map("n", "<C-n>", "<CMD>NvimTreeToggle<CR>", opt)

-- 标签页切换
map("n", "<C-left>", "<CMD>bprevious<CR>", opt)
map("n", "<C-right>", "<CMD>bnext<CR>", opt)

-- 撤销
map("n", "<C-z>", "<CMD>undo<CR>", opt)
map("i", "<C-z>", "<CMD>undo<CR>", opt)

-- 模糊搜索
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<Space>ff', builtin.find_files, {})
vim.keymap.set('n', '<Space>fg', builtin.live_grep, {})
vim.keymap.set('n', '<Space>fb', builtin.buffers, {})
vim.keymap.set('n', '<Space>fh', builtin.help_tags, {})

-- 注释
map("n", "<C-\\>", "<CMD>CommentToggle<CR>", opt)
map("i", "<C-\\>", "<CMD>CommentToggle<CR>", opt)