return {
  "nvim-mini/mini.files",
  version = false,
  keys = {
    {
      "<leader>e",
      function()
        require("mini.files").open(vim.api.nvim_buf_get_name(0), false)
      end,
      desc = "Open mini.files (current file)",
    },
    {
      "<leader>E",
      function()
        require("mini.files").open(vim.loop.cwd(), false)
      end,
      desc = "Open mini.files (cwd)",
    },
  },
  opts = {
    windows = {
      preview = false,
      width_focus = 30,
      width_nofocus = 30,
      width_preview = 60,
    },
    options = {
      use_as_default_explorer = true,
    },
    mappings = {
      go_in = "l",
      go_in_plus = "<CR>",
      go_out = "h",
      go_out_plus = "-",
      reset = "<BS>",
      show_help = "g?",
      synchronize = "=",
      trim_left = "<",
      trim_right = ">",
    },
  },
  config = function(_, opts)
    require("mini.files").setup(opts)

    -- Optional: Auto-close on file open
    local augroup = vim.api.nvim_create_augroup("MiniFilesClose", {})
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesAction*",
      group = augroup,
      callback = function(event)
        if event.data.action == "open" then
          require("mini.files").close()
        end
      end,
    })
  end,
}
