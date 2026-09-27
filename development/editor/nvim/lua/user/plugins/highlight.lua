return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
      "html",
      "css",
      "xml",
      "json",
      "yaml",
      "toml",
      "vim",
      "ini",
      "dockerfile",
      "lua",
      "sql",
      "javascript",
      "typescript",
      "rust",
      "cpp",
      "zig",
      "java",
      "erlang",
      "elixir",
      "heex",
    })
  end,
}