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
      highlights = {
        TermCursor = { bg = "#abb2bf", fg = "#1e222a" },
        TermCursorNC = { bg = "#5c6370", fg = "#1e222a" },
        UserTerminalNormal = { bg = "#1e222a", fg = "#abb2bf" },
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
