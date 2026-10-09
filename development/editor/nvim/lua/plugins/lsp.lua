local lsp_servers = {
  "rust_analyzer",
  "elixirls",
  "lua_ls",
}

return {
  {
    "AstroNvim/astrolsp",
    opts = {
      servers = lsp_servers,
      mappings = {
        n = {
          ["<Leader>lf"] = false,
          ["<Leader>lr"] = false,
          ["<Leader>lF"] = { function() vim.lsp.buf.format() end, desc = "格式化代码" },
          ["<Leader>lR"] = { function() vim.lsp.buf.rename() end, desc = "重命名符号 (LSP Rename)" },
        },
        v = {
          ["<Leader>lf"] = false,
          ["<Leader>lr"] = false,
          ["<Leader>lF"] = { function() vim.lsp.buf.format() end, desc = "格式化选中代码" },
        },
      },
      config = {
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = { command = "clippy" },
            },
          },
        },
        elixirls = {
          settings = {
            elixirLS = { dialyzerEnabled = true },
          },
        },
      },
    },
  },

  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, lsp_servers)
    end,
  },
}
