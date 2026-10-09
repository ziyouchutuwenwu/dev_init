return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    if not opts.options then opts.options = {} end
    if not opts.options.opt then opts.options.opt = {} end

    opts.options.opt.clipboard = ""
    return opts
  end,
  init = function()

    vim.g.clipboard = {
      name = "osc52",
      copy = {
        ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
        ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
      },
      paste = {
        ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
        ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
      },
    }
    vim.opt.clipboard = ""
  end,
}
