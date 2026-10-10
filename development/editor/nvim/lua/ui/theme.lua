local bg = "#282c34"

-- 状态栏背景色预设（当前已设为纯黑 #000000）
local status_colors = {
  dark = { name = "纯黑底座 (#000000 极致深黑)", bg = "#000000", fg = "#abb2bf" },
  charcoal = { name = "深炭暗灰 (#181b22)", bg = "#181b22", fg = "#abb2bf" },
  navy = { name = "幽邃深海蓝 (高级微蓝暗调)", bg = "#1a2333", fg = "#cad2e0" },
  forest = { name = "幽邃墨竹绿 (低饱和墨绿暗调)", bg = "#19261d", fg = "#cad2c5" },
  surface = { name = "浮雕微亮阶 (略亮于编辑区)", bg = "#313642", fg = "#abb2bf" },
  none = { name = "完全透明 (无底色)", bg = "NONE", fg = "#abb2bf" },
  default = { name = "原版同色 (#282c34 完全无边界)", bg = "#282c34", fg = "#abb2bf" },
}

-- 当前默认选择：纯黑 (#000000)
local current_status_color = "dark"

_G._current_status_color = current_status_color
_G.status_colors = status_colors
_G.get_statusline_hl = function()
  local key = _G._current_status_color or current_status_color
  local p = status_colors[key] or status_colors.dark
  return { bg = p.bg, fg = p.fg }
end

local st_preset = _G.get_statusline_hl()

return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    init = function()
      local function apply_color(key, notify)
        local preset = status_colors[key]
        if not preset then
          vim.notify("未知的预设: " .. tostring(key) .. "\n可选: dark, navy, forest, surface, none, default", vim.log.levels.WARN)
          return
        end
        _G._current_status_color = key
        vim.api.nvim_set_hl(0, "StatusLine", { bg = preset.bg, fg = preset.fg })
        vim.api.nvim_set_hl(0, "StatusLineNC", { bg = preset.bg, fg = preset.fg })
        if package.loaded["astroui.status.heirline"] then
          require("astroui.status.heirline").refresh_colors()
        end
        vim.cmd("redrawstatus")
        if notify ~= false then
          vim.notify("底栏已切换为: " .. preset.name .. " (" .. tostring(preset.bg) .. ")", vim.log.levels.INFO)
        end
      end

      -- 注册 :StatusColor [name] 命令，不带参数时在精选设计方案间循环切换
      local cycle_list = { "dark", "navy", "forest", "surface" }
      vim.api.nvim_create_user_command("StatusColor", function(opts)
        local arg = opts.args and vim.trim(opts.args)
        if arg == "" then
          local cur = _G._current_status_color or current_status_color
          local idx = 1
          for i, k in ipairs(cycle_list) do
            if k == cur then idx = i break end
          end
          local next_key = cycle_list[(idx % #cycle_list) + 1]
          apply_color(next_key)
        else
          apply_color(arg)
        end
      end, {
        nargs = "?",
        complete = function()
          return { "dark", "charcoal", "navy", "forest", "black", "surface", "none", "default" }
        end,
        desc = "快速切换最底部状态栏颜色风格 (dark/charcoal/navy/forest/black/surface/none/default)",
      })

      -- 在配色重载时保持所选颜色
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local cur = _G._current_status_color
          if cur and status_colors[cur] then
            local p = status_colors[cur]
            vim.api.nvim_set_hl(0, "StatusLine", { bg = p.bg, fg = p.fg })
            vim.api.nvim_set_hl(0, "StatusLineNC", { bg = p.bg, fg = p.fg })
          end
        end,
      })
    end,
    opts = {
      caching = false,
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
        highlight_inactive_windows = false,
      },
      highlights = {
        Normal = { bg = bg, fg = "#abb2bf" },
        NormalNC = { bg = bg, fg = "#abb2bf" },
        SignColumn = { bg = bg },
        SignColumnNC = { bg = bg },
        LineNr = { bg = bg, fg = "#495162" },
        LineNrNC = { bg = bg, fg = "#495162" },
        CursorLineNr = { bg = bg, fg = "#abb2bf" },
        CursorLineNrNC = { bg = bg, fg = "#495162" },
        CursorLine = { bg = "#2d313b" },
        CursorLineNC = { bg = bg },
        FoldColumn = { bg = bg, fg = "#495162" },
        FoldColumnNC = { bg = bg, fg = "#495162" },
        Folded = { bg = bg, fg = "#5c6370" },
        FoldedNC = { bg = bg, fg = "#5c6370" },
        WinBar = { bg = bg, fg = "#abb2bf" },
        WinBarNC = { bg = bg, fg = "#abb2bf" },
        WinSeparator = { bg = bg, fg = "#3e4452" },
        VertSplit = { bg = bg, fg = "#3e4452" },
        StatusLine = { bg = st_preset.bg, fg = st_preset.fg },
        StatusLineNC = { bg = st_preset.bg, fg = st_preset.fg },
        EndOfBuffer = { bg = bg, fg = bg },
        NeoTreeNormal = { bg = bg, fg = "#abb2bf" },
        NeoTreeNormalNC = { bg = bg, fg = "#abb2bf" },
        NeoTreeWinSeparator = { bg = bg, fg = "#3e4452" },
        NeoTreeVertSplit = { bg = bg, fg = "#3e4452" },
        EdgyNormal = { bg = bg },
        EdgyWinBar = { bg = bg },
        UserTerminalNormal = { bg = bg, fg = "#abb2bf" },
        TermCursor = { bg = "#abb2bf", fg = "#1e222a" },
        TermCursorNC = { bg = "#5c6370", fg = "#1e222a" },
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
