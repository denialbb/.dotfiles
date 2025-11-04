return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false, -- Load early for speed
  version = false, -- Use latest

  opts = {
    provider = "ollama",
    providers = {
      ollama = {
        endpoint = "http://localhost:11434",
        model = "qwen2.5-coder:7b",
        concurrent_requests = 1,
        timeout = 120,
        throttle_ms = 500,
        parse_stream = true,
      },
      phi = {
        endpoint = "http://localhost:11434",
        model = "phi3.5:3.8b-mini-instruct-q4_1", -- Fast model
        concurrent_requests = 1,
        timeout = 120,
        __inherited_from = "ollama",
        parse_stream = true,
      },
    },

    behaviour = {
      auto_suggestions = true, -- Inline ghost text (Copilot-style)
      auto_suggestions_provider = "phi",
      auto_suggestions_keymaps = {
        accept = "<Tab>",
        dismiss = "<S-Tab>",
      },
      auto_set_highlight_group = true,
      auto_apply_diff_after_generation = false, -- Review before apply
      support_paste_image = false, -- No need for local
      auto_set_keymaps = true,
      auto_apply_diff = {
        apply = false, -- Manual review
        diff_patience = 100, -- Quick diffs
      },
    },

    windows = {
      position = "right", -- Sidebar chat
      wrap = true,
      width = 50, -- Roomy for code diffs
      sidebar_header = {
        align = "center",
        rounded = true,
      },
    },
    highlights = {
      diff = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },

    mappings = {
      ask = "<leader>as",
      edit = "<leader>ae",
      apply = "<leader>aa",
      refresh = "<leader>ar",
      close = "<leader>aq",
      toggle = {
        sidebar = "<leader>at",
      },
    },

    -- === PROMPTS: Coding-Focused Library ===
    prompts = {
      -- Quick actions
      Ask = {
        prompt = "Ask Avante about the current file or selection",
        model = "qwen2.5-coder:7b",
      },
      Edit = {
        prompt = "Edit the current selection or file. Only return the diff in markdown format.",
        model = "qwen2.5-coder:7b",
      },
      Review = {
        prompt = "Review the code for bugs, performance, and style. Suggest improvements.",
        model = "qwen2.5-coder:7b",
      },
      Test = {
        prompt = "Write comprehensive unit tests for the selected code.",
        model = "qwen2.5-coder:7b",
      },
      Debug = {
        prompt = "Debug this code: explain errors and provide a fixed version.",
        model = "qwen2.5-coder:7b",
      },
      Optimize = {
        prompt = "Optimize this code for speed and readability. Return diff.",
        model = "qwen2.5-coder:7b",
      },
      Document = {
        prompt = "Add detailed comments and docstrings to this code.",
        model = "qwen2.5-coder:7b",
      },
    },

    -- === CUSTOM: Tools & Extensions ===
    -- Enable tool calling if Qwen supports (experimental)
    tools = {
      enabled = true,
      run_command = true, -- Execute shell commands
      edit_file = true, -- In-place edits
    },
  },
  build = "make", -- Required for binary deps
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua", -- Optional fallback (if you add it)
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- Required for Avante
          use_absolute_path = true,
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = { file_types = { "markdown", "Avante" } },
      ft = { "markdown", "Avante" },
    },
  },
}
