return {
  "ibhagwan/fzf-lua",
  bind = {},
  opts = function(_, opts)
    vim.keymap.set("n", "<C-f>", ":FzfLua files<CR>", { desc = "Find files" })
    vim.keymap.set(
      "n",
      "<leader>fg",
      ":FzfLua live_grep<CR>",
      { desc = "Find grep" }
    )
    opts.previewers = {
      builtin = {
        -- fzf-lua is very fast, but it really struggled to preview a couple files
        -- in a repo. Those files were very big JavaScript files (1MB, minified, all on a single line).
        -- It turns out it was Treesitter having trouble parsing the files.
        -- With this change, the previewer will not add syntax highlighting to files larger than 100KB
        -- (Yes, I know you shouldn't have 100KB minified files in source control.)
        syntax_limit_b = 1024 * 100, -- 100KB
      },
    }
    opts.fzf_opts = {
      ["--no-scrollbar"] = "",
      ["--info"] = "inline-right",
      ["--layout"] = "default",
      ["--border"] = "none",
      ["--pointer"] = ">",
      ["--marker"] = "•",
      ["--padding"] = "0%,0%",
      ["--margin"] = "0%,0%",
    }
    opts.winopts = {
      height = 0.28,
      width = 0.25,
      row = 0.38,
      col = 0.50,
      border = "none",
      preview = {
        layout = "vertical",
        vertical = "up:48%",
        hidden = "hidden",
        win_options = { -- Remove preview padding
          winblend = 50,
        },
      },
      win_options = {
        winblend = 50,
      },
    }
  end,
}
