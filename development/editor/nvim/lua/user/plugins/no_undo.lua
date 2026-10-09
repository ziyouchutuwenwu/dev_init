return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    if not opts.options then opts.options = {} end
    if not opts.options.opt then opts.options.opt = {} end

    opts.options.opt.undofile = false
    opts.options.opt.shada = ""

    opts.options.opt.relativenumber = false
    opts.options.opt.number = true

    if not opts.mappings then opts.mappings = {} end
    if not opts.mappings.n then opts.mappings.n = {} end
    if not opts.mappings.t then opts.mappings.t = {} end
    if not opts.mappings.i then opts.mappings.i = {} end
    opts.mappings.n["<F7>"] = false
    opts.mappings.t["<F7>"] = false
    opts.mappings.i["<F7>"] = false

    return opts
  end,
}
