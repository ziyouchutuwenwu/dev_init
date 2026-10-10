local function get_sidebar_width()
  local cols = vim.o.columns
  local w = math.floor(cols * 0.20)
  return math.max(math.min(w, 35), 18)
end

return {
  {
    "folke/edgy.nvim",
    lazy = false,
    opts = {
      animate = {
        enabled = false,
      },
      left = {
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
          pinned = false,
          open = "Neotree position=left filesystem",
        },

        {
          title = "大纲",
          ft = "aerial",
          pinned = false,
          open = function()
            require("aerial").open()
          end,
        },

        {
          title = "任务[r/e]",
          ft = "overseer_tasks",
          pinned = false,
          open = function()
            require("plugins.modules.tasks").open_task_list()
          end,
        },

        {
          title = "任务监视器",
          ft = "OverseerList",
          pinned = false,
          open = function()
            require("overseer").open()
          end,
        },
      },
      options = {
        left = { size = get_sidebar_width },
      },
      wo = {
        winbar = true,
        winfixwidth = false,
        winfixheight = false,
        statusline = " ",
      },
      keys = {
        ["<C-Right>"] = function(win)
          local eb = win.view.edgebar
          local cur_w = type(eb.size) == "function" and eb.size() or eb.size
          local new_w = math.max((cur_w or 30) + 3, 1)
          eb.size = new_w
          local cfg = require("edgy.config")
          if cfg.options and cfg.options[eb.pos] then
            cfg.options[eb.pos].size = new_w
          end
          for _, w in ipairs(eb.wins) do
            if w:is_valid() then
              vim.w[w.win].edgy_width = nil
            end
          end
          require("edgy.layout").update()
        end,
        ["<C-Left>"] = function(win)
          local eb = win.view.edgebar
          local cur_w = type(eb.size) == "function" and eb.size() or eb.size
          local new_w = math.max((cur_w or 30) - 3, 1)
          eb.size = new_w
          local cfg = require("edgy.config")
          if cfg.options and cfg.options[eb.pos] then
            cfg.options[eb.pos].size = new_w
          end
          for _, w in ipairs(eb.wins) do
            if w:is_valid() then
              vim.w[w.win].edgy_width = nil
            end
          end
          require("edgy.layout").update()
        end,
        ["<C-Up>"] = function(win) win:resize("height", 2) end,
        ["<C-Down>"] = function(win) win:resize("height", -2) end,
      },
    },
    config = function(_, opts)
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
        if self.vertical and #self.wins > 0 and is_mouse_dragging then
          for _, w in ipairs(self.wins) do
            if w.visible and w:is_valid() then
              local actual_w = vim.api.nvim_win_get_width(w.win)
              local cur_w = type(self.size) == "function" and self.size() or self.size
              if actual_w >= 1 and actual_w ~= cur_w then
                self.size = actual_w
                local cfg = require("edgy.config")
                if cfg.options and cfg.options[self.pos] then
                  cfg.options[self.pos].size = actual_w
                end
              end
              vim.w[w.win].edgy_width = nil
            end
          end
        end
        return orig_resize(self)
      end

      local augroup = vim.api.nvim_create_augroup("UserEdgyProportionalResize", { clear = true })
      vim.api.nvim_create_autocmd("VimResized", {
        group = augroup,
        callback = function()
          local cfg = require("edgy.config")
          local eb = cfg.layout.left
          if eb then
            eb.size = get_sidebar_width
            if cfg.options and cfg.options.left then
              cfg.options.left.size = get_sidebar_width
            end
            for _, w in ipairs(eb.wins) do
              if w:is_valid() then
                vim.w[w.win].edgy_width = nil
              end
            end
          end
          require("edgy.layout").update()
        end,
      })

      require("edgy").setup(opts)
    end,
  },
}
