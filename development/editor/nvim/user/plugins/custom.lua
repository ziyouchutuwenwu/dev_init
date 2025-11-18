return {
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, _)
      -- 自动换行
      vim.cmd('set wrap')
    end,
  }
}
