return {
  -- 使用 edgy.nvim 统一管理左侧边栏：实现与 VS Code 完全一致的“文件树在上、大纲居中、任务在底”
  {
    "folke/edgy.nvim",
    lazy = false,
    opts = {
      animate = {
        enabled = false, -- 关闭动画，确保布局瞬时响应、杜绝高度泄漏与抖动
      },
      left = {
        -- 1. 顶部：文件资源管理器 (Neo-tree)
        {
          title = "文件资源管理器",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "filesystem"
          end,
          pinned = false,
          open = "Neotree position=left filesystem",
        },
        -- 2. 中间：代码大纲 (Aerial)
        {
          title = "代码大纲",
          ft = "aerial",
          pinned = false,
          open = function()
            require("aerial").open()
          end,
        },
        -- 3. 底部：任务管理器 (Overseer)
        {
          title = "任务管理器",
          ft = "OverseerList",
          pinned = false,
          open = function()
            require("overseer").open()
          end,
        },
      },
      options = {
        left = { size = 32 },
      },
      wo = {
        winbar = true,
        winfixwidth = true,
        winfixheight = false,
      },
    },
  },
}
