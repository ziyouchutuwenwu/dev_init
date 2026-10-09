return {
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
      colorscheme = "onedark",
    },
  },
}
