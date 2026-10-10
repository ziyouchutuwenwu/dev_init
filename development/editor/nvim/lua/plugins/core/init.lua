require("plugins.core.options")
require("plugins.core.keymaps")
return {
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = { ["<F7>"] = false },
        t = { ["<F7>"] = false },
        i = { ["<F7>"] = false },
      },
    },
  },
  { import = "plugins.core.clipboard" },
  { import = "plugins.core.no_recent" },
  { import = "plugins.core.no_undo" },
}
