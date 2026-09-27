local lsp_servers = {
  "rust_analyzer",
  "elixirls",
  "lua_ls",
}

return {
  -- 1. 运行配置（参数与服务注册）
  {
    "AstroNvim/astrolsp",
    opts = {
      servers = lsp_servers,
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

  -- 2. 自动下载安装（缺失时自动从 Mason 补全）
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, lsp_servers)
    end,
  },
}
