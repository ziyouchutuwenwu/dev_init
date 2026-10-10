return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    if not opts.options then opts.options = {} end
    if not opts.options.opt then opts.options.opt = {} end

    opts.options.opt.undofile = false
    opts.options.opt.shada = ""

    opts.options.opt.relativenumber = false
    opts.options.opt.number = true

    return opts
  end,
}
