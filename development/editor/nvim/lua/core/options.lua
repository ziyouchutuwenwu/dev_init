vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.mousemodel = "popup_setpos"
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.splitkeep = "screen"
vim.opt.title = true
vim.opt.titlestring = "%t%( %m%) - nvim"

local function apply_highlights()
  local bg = "#282c34"
  vim.api.nvim_set_hl(0, "Normal", { bg = bg, fg = "#abb2bf" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = bg, fg = "#abb2bf" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = bg })
  vim.api.nvim_set_hl(0, "SignColumnNC", { bg = bg })
  vim.api.nvim_set_hl(0, "LineNr", { bg = bg, fg = "#495162" })
  vim.api.nvim_set_hl(0, "LineNrNC", { bg = bg, fg = "#495162" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { bg = bg, fg = "#abb2bf" })
  vim.api.nvim_set_hl(0, "CursorLineNrNC", { bg = bg, fg = "#495162" })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2d313b" })
  vim.api.nvim_set_hl(0, "CursorLineNC", { bg = bg })
  vim.api.nvim_set_hl(0, "FoldColumn", { bg = bg, fg = "#495162" })
  vim.api.nvim_set_hl(0, "FoldColumnNC", { bg = bg, fg = "#495162" })
  vim.api.nvim_set_hl(0, "Folded", { bg = bg, fg = "#5c6370" })
  vim.api.nvim_set_hl(0, "FoldedNC", { bg = bg, fg = "#5c6370" })
  vim.api.nvim_set_hl(0, "WinBar", { bg = bg, fg = "#abb2bf" })
  vim.api.nvim_set_hl(0, "WinBarNC", { bg = bg, fg = "#abb2bf" })
  vim.api.nvim_set_hl(0, "WinSeparator", { bg = bg, fg = "#3e4452" })
  vim.api.nvim_set_hl(0, "VertSplit", { bg = bg, fg = "#3e4452" })
  local st_hl = type(_G.get_statusline_hl) == "function" and _G.get_statusline_hl()
  if st_hl then
    vim.api.nvim_set_hl(0, "StatusLine", st_hl)
    vim.api.nvim_set_hl(0, "StatusLineNC", st_hl)
  end
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = bg, fg = bg })
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = bg, fg = "#abb2bf" })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = bg, fg = "#abb2bf" })
  vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { bg = bg, fg = "#3e4452" })
  vim.api.nvim_set_hl(0, "NeoTreeVertSplit", { bg = bg, fg = "#3e4452" })
  vim.api.nvim_set_hl(0, "EdgyNormal", { bg = bg })
  vim.api.nvim_set_hl(0, "EdgyWinBar", { bg = bg })
  vim.api.nvim_set_hl(0, "UserTerminalNormal", { bg = bg, fg = "#abb2bf" })
  vim.api.nvim_set_hl(0, "TermCursor", { bg = "#abb2bf", fg = "#1e222a" })
  vim.api.nvim_set_hl(0, "TermCursorNC", { bg = "#5c6370", fg = "#1e222a" })
end

apply_highlights()

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  callback = apply_highlights,
})
