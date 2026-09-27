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
      mappings = {
        n = {
          -- 解除默认占用的 <Leader>lf (格式化) 和 <Leader>lr (重命名)，让位给用户专属搜索替换体系
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

  -- 2. 自动下载安装（缺失时自动从 Mason 补全）
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, lsp_servers)
    end,
  },
}
