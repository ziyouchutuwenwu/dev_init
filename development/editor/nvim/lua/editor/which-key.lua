return {
  {
    "folke/which-key.nvim",
    opts = {
      triggers = {
        { "<auto>", mode = "nso" },
      },
      defer = function(ctx)
        return vim.list_contains({ "v", "V", "<C-V>", "s", "S" }, ctx.mode)
      end,
    },
  },
}
