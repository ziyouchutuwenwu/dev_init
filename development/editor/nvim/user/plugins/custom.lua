vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd('set wrap')
    vim.cmd('set linebreak')
    vim.cmd('set breakindent')
    -- 修复命令补全行为，Tab 不会跳过第一个选项
    vim.cmd('set wildmenu')
    vim.cmd('set wildmode=longest:full,full')
  end,
})
