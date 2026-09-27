-- 补全配置适配 AstroNvim v6 (blink.cmp)
-- AstroNvim v6 默认使用 blink.cmp 作为补全引擎
-- 这里仅追加需要的快捷键（不与 AstroNvim 默认冲突）

return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      -- 新增文档滚动快捷键（AstroNvim 默认使用 C-u/C-d）
      ["<C-b>"] = { "scroll_documentation_up", "fallback" },
      ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    },
  },
}
