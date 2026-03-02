vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd('set wrap')
    vim.cmd('set linebreak')
    vim.cmd('set breakindent')
  end,
})
