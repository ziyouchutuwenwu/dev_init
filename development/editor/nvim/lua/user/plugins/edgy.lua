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
        -- 1. 顶部：文件资源管理器 (Neo-tree: 完美兼容 files, buffers, git 全部三种视图源自由切换)
        {
          title = function()
            local source = vim.b.neo_tree_source
            if source == "buffers" then
              return "缓冲区列表"
            elseif source == "git_status" then
              return "Git 变更状态"
            end
            return "文件资源管理器"
          end,
          ft = "neo-tree",
          size = { width = 32 },
          pinned = false,
          open = "Neotree position=left filesystem",
        },
        -- 2. 中间：代码大纲 (Aerial)
        {
          title = "代码大纲",
          ft = "aerial",
          size = { width = 32 },
          pinned = false,
          open = function()
            require("aerial").open()
          end,
        },
        -- 3. 底部：任务列表 (所有 tasks.json 及项目任务，Alt+3)
        {
          title = "任务列表 [r刷新 e编辑]",
          ft = "overseer_tasks",
          size = { width = 32 },
          pinned = false,
          open = function()
            require("user.plugins.tasks").open_task_list()
          end,
        },
        -- 4. 任务监视器 (Overseer 运行中任务监视器)
        {
          title = "任务监视器",
          ft = "OverseerList",
          size = { width = 32 },
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
        winfixwidth = false, -- 允许左右拖动改变宽度
        winfixheight = false,
      },
      keys = {
        -- 快捷按键微调宽度 / 高度
        ["<C-Right>"] = function(win) win:resize("width", 3) end,
        ["<C-Left>"] = function(win) win:resize("width", -3) end,
        ["<C-Up>"] = function(win) win:resize("height", 2) end,
        ["<C-Down>"] = function(win) win:resize("height", -2) end,
      },
    },
    config = function(_, opts)
      -- 增强 edgy：通过精确捕获鼠标拖拽事件，支持鼠标左右拖动边框，同时杜绝新窗口打开时误拉宽侧边栏
      local Edgebar = require("edgy.edgebar")
      local orig_resize = Edgebar.resize
      local is_mouse_dragging = false

      vim.on_key(function(key)
        local char = vim.fn.keytrans(key)
        if char:find("Drag") then
          is_mouse_dragging = true
        elseif char:find("Release") or char:find("Up") then
          is_mouse_dragging = false
        end
      end)

      Edgebar.resize = function(self)
        -- 仅当用户正在用鼠标拖动边框时，才更新 edgebar 的目标宽度
        if self.vertical and #self.wins > 0 and is_mouse_dragging then
          for _, w in ipairs(self.wins) do
            if w.visible and w:is_valid() then
              local actual_w = vim.api.nvim_win_get_width(w.win)
              if actual_w >= 15 and actual_w ~= self.size then
                self.size = actual_w
                local cfg = require("edgy.config")
                if cfg.options and cfg.options[self.pos] then
                  cfg.options[self.pos].size = actual_w
                end
              end
            end
          end
        end
        return orig_resize(self)
      end

      require("edgy").setup(opts)
    end,
  },
}
