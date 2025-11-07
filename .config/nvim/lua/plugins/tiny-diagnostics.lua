return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    opts = {
      -- Available: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
      preset = "minimal",
      transparent_bg = true,
      transparent_cursorline = true,
      overflow = {
        mode = "oneline", -- "wrap": split into lines, "none": no truncation, "oneline": keep single line
        padding = 0, -- Extra characters to trigger wrapping earlier
      },

      hi = {
        error = "DiagnosticError", -- Highlight for error diagnostics
        warn = "NonText", -- Highlight for warning diagnostics
        info = "NonText", -- Highlight for info diagnostics
        hint = "NonText", -- Highlight for hint diagnostics
        arrow = "NonText", -- Highlight for the arrow pointing to diagnostic
        background = "CursorLine", -- Background highlight for diagnostics
        mixing_color = "Normal", -- Color to blend background with (or "None")
      },
      add_messages = {
        messages = true, -- Show full diagnostic messages
        display_count = true, -- Show diagnostic count instead of messages when cursor not on line
        use_max_severity = true, -- When counting, only show the most severe diagnostic
        show_multiple_glyphs = true, -- Show multiple icons for multiple diagnostics of same severity
      },
      multilines = {
        enabled = true, -- Enable support for multiline diagnostic messages
        always_show = true, -- Always show messages on all lines of multiline diagnostics
        trim_whitespaces = true, -- Remove leading/trailing whitespace from each line
        tabstop = 4, -- Number of spaces per tab when expanding tabs
        -- severity = nil, -- Filter multiline diagnostics by severity (e.g., { vim.diagnostic.severity.ERROR })
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = { diagnostics = { virtual_text = false } },
  },
}
