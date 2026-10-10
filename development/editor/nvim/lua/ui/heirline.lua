return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    local status = require("astroui.status")
    local disabled_fts = {
      ["neo-tree"] = true,
      ["aerial"] = true,
      ["overseer_tasks"] = true,
      ["OverseerList"] = true,
      ["edgy"] = true,
    }

    opts.statusline = {
      hl = { fg = "fg", bg = "bg" },
      fallthrough = false,
      {
        condition = function(self)
          local bufnr = (self and self.bufnr) or vim.api.nvim_get_current_buf()
          return disabled_fts[vim.bo[bufnr].filetype] == true
        end,
        status.component.fill(),
      },
      opts.statusline,
    }
    return opts
  end,
}
