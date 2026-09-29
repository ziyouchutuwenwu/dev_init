vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd('set wrap')
    vim.cmd('set linebreak')
    vim.cmd('set breakindent')
    -- 优化鼠标行为：右键移动光标并扩展选区，防止终端右键乱粘贴导致错位
    vim.opt.mousemodel = "extend"
    -- 禁用相对行号
    vim.opt.relativenumber = false
    vim.opt.number = true
    -- 稳定分割窗口，防止切换文件/缓冲区时边缘窗口跳动缩水
    vim.opt.splitkeep = "screen"
    -- 开启终端标题自动同步当前文件名
    vim.opt.title = true
    vim.opt.titlestring = "%t%( %m%) - nvim"
  end,
})
