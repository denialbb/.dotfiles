return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-telescope/telescope-fzf-native.nvim" },
  opts = {
    defaults = {
      file_ignore_patterns = {
        "%.git/",
        "%.DS_Store",
        "%.jpg",
        "%.png",
        "%.pdf",
        "node_modules/",
        "target/",
        "vendor/",
        "%.lock$",
        "%.min%.[jc]ss?$",
      },
      selection_caret = "❯ ",
      prompt_prefix = ":",
      entry_prefix = "  ",
      results_title = false,
      prompt_title = false,
      preview_title = false,
      border = true,
      preview = false,
      layout_strategy = "vertical",
      layout_config = {
        height = 20,
        width = 50,
        prompt_position = "bottom",
      },
      path_display = { "smart" },
      mappings = {
        i = {
          ["<Esc>"] = "close",
          ["<C-c>"] = "close",
          ["?"] = require("telescope.actions.layout").toggle_preview,
        },
      },
    },
    pickers = {
      find_files = {
        previewer = false,
        find_command = {
          "fd",
          "--type",
          "f",
          "--strip-cwd-prefix",
          "--hidden",
          "--no-ignore",
        },
        cache_picker = { num_pickers = 5, timeout = 60 },
      },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf")
  end,
}
