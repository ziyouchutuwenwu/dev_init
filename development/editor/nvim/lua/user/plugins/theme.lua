return {
  -- 主题：OneDarkPro（最贴近 VS Code Yi Dark / Atom One Dark 的现代主题）
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    opts = {
      styles = {
        types = "NONE",
        methods = "NONE",
        numbers = "NONE",
        strings = "NONE",
        comments = "italic",
        keywords = "bold,italic",
        constants = "NONE",
        functions = "NONE",
        operators = "NONE",
        variables = "NONE",
        parameters = "NONE",
        conditionals = "italic",
        virtual_text = "NONE",
      },
      options = {
        cursorline = true,
        transparency = false,
        terminal_colors = true,
        highlight_inactive_windows = true,
      },
    },
  },
  {
    "AstroNvim/astroui",
    opts = {
      colorscheme = "onedark", -- 经典 Atom One Dark 风格；可选：onedark_vivid, onedark_dark
    },
  },
}
