return {
  -- 主题：Catppuccin（配置与 AstroNvim UI 体系完全接合）
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha", -- 现代暗色调：latte, frappe, macchiato, mocha
      transparent_background = false,
      integrations = {
        aerial = true,
        blink_cmp = true,
        gitsigns = true,
        neotree = true,
        treesitter = true,
        which_key = true,
      },
    },
  },
  {
    "AstroNvim/astroui",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
