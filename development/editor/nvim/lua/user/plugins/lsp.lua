return {
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      local is_linux = false
      local uname = vim.fn.system("uname -s"):gsub("%s+", "")
      if uname == "Linux" then
        is_linux = true
      end

      local lsp_list = {
        -- "elixir-ls",
      }

      -- bsd 下不兼容
      if is_linux then
        table.insert(lsp_list, "lua-language-server")
      end

      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, lsp_list)
    end,
  },
}
