-- 名字是 :Mason 手动安装的时候，后面的灰色的名字
return {
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        -- lua_ls 在 bsd 下不支持
        -- "lua_ls",
        "elixirls"
      })
    end,
  },
}
