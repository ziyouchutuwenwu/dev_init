vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.mousemodel = "extend"
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.splitkeep = "screen"
vim.opt.title = true
vim.opt.titlestring = "%t%( %m%) - nvim"

vim.api.nvim_set_hl(0, "TermCursor", { bg = "#abb2bf", fg = "#1e222a" })
vim.api.nvim_set_hl(0, "TermCursorNC", { bg = "#5c6370", fg = "#1e222a" })
vim.api.nvim_set_hl(0, "UserTerminalNormal", { bg = "#1e222a", fg = "#abb2bf" })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("set wrap")
    vim.cmd("set linebreak")
    vim.cmd("set breakindent")
    vim.opt.mousemodel = "extend"
    vim.opt.relativenumber = false
    vim.opt.number = true
    vim.opt.splitkeep = "screen"
    vim.opt.title = true
    vim.opt.titlestring = "%t%( %m%) - nvim"
    vim.api.nvim_set_hl(0, "TermCursor", { bg = "#abb2bf", fg = "#1e222a" })
    vim.api.nvim_set_hl(0, "TermCursorNC", { bg = "#5c6370", fg = "#1e222a" })
    vim.api.nvim_set_hl(0, "UserTerminalNormal", { bg = "#1e222a", fg = "#abb2bf" })
  end,
})
