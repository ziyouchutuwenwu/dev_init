return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    if not opts.options then opts.options = {} end
    if not opts.options.opt then opts.options.opt = {} end
    -- 强制覆盖撤销设置
    opts.options.opt.undofile = false
    opts.options.opt.shada = ""
    -- 禁用相对行号，始终显示普通绝对行号（对齐 VS Code 体验）
    opts.options.opt.relativenumber = false
    opts.options.opt.number = true
    return opts
  end,
}