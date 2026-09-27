return {
  -- 代码大纲视图 (基于 aerial.nvim)
  "stevearc/aerial.nvim",
  cmd = { "AerialToggle", "AerialOpen", "AerialClose", "AerialNavToggle" },
  opts = {
    on_attach = function(bufnr)
      vim.keymap.set("n", "{", "<Cmd>AerialPrev<CR>", { buffer = bufnr, desc = "跳转上一个符号" })
      vim.keymap.set("n", "}", "<Cmd>AerialNext<CR>", { buffer = bufnr, desc = "跳转下一个符号" })
    end,
    layout = {
      max_width = { 40, 0.25 },
      width = 30,
      default_direction = "prefer_left",
    },
    show_guides = true,
  },
  keys = {
    {
      "<M-2>",
      function()
        if package.loaded["edgy"] then
          local main_wins = require("edgy.editor").list_wins().main
          if not main_wins[vim.api.nvim_get_current_win()] then
            require("edgy.editor").goto_main()
          end
        end
        require("aerial").toggle()
      end,
      desc = "切换代码大纲 (Alt+2)",
    },
    {
      "<Leader>o",
      function()
        if package.loaded["edgy"] then
          local main_wins = require("edgy.editor").list_wins().main
          if not main_wins[vim.api.nvim_get_current_win()] then
            require("edgy.editor").goto_main()
          end
        end
        require("aerial").toggle()
      end,
      desc = "切换代码大纲 (Outline)",
    },
    {
      "<F8>",
      function()
        if package.loaded["edgy"] then
          local main_wins = require("edgy.editor").list_wins().main
          if not main_wins[vim.api.nvim_get_current_win()] then
            require("edgy.editor").goto_main()
          end
        end
        require("aerial").toggle()
      end,
      desc = "切换代码大纲 (F8)",
    },
  },
}
