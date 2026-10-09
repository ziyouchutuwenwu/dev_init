vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd('set wrap')
    vim.cmd('set linebreak')
    vim.cmd('set breakindent')

    vim.opt.mousemodel = "extend"

    vim.opt.relativenumber = false
    vim.opt.number = true

    vim.opt.splitkeep = "screen"

    vim.opt.title = true
    vim.opt.titlestring = "%t%( %m%) - nvim"

    pcall(vim.keymap.del, "n", "<F7>")
    pcall(vim.keymap.del, "t", "<F7>")
    pcall(vim.keymap.del, "i", "<F7>")
  end,
})
