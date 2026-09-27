vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd('set wrap')
    vim.cmd('set linebreak')
    vim.cmd('set breakindent')
    -- 优化鼠标行为：右键移动光标并扩展选区，防止终端右键乱粘贴导致错位
    vim.opt.mousemodel = "extend"
  end,
})
