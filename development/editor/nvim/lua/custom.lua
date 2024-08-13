return {
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, _)
      -- 设置换行
      vim.cmd('set wrap')
    end,
  },
  {
    "AstroNvim/AstroNvim",
    opts = function(_, _)
      -- 上下键代替 C-N 和 C-P
      vim.cmd('cnoremap <Up> <C-p>')
      vim.cmd('cnoremap <Down> <C-n>')
    end,
  }
}
