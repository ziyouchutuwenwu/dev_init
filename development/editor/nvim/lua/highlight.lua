return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
      "html",
      "xml",
      "json",
      "vim",
      "lua",
      "sql",
      "typescript",
      "java",
      "erlang",
      "elixir",
    })
  end,
}
