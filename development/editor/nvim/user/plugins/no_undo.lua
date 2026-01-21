return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    if not opts.options then opts.options = {} end
    if not opts.options.opt then opts.options.opt = {} end
    -- 强制覆盖撤销设置
    opts.options.opt.undofile = false
    opts.options.opt.shada = ""
    opts.options.opt.undolevels = 1000
    return opts
  end,
}