-- ~/.config/nvim/lua/plugins/conform.lua
return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "black", "isort" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      json = { "prettier" },
      markdown = { "prettier" },
      yaml = { "prettier" },
      go = { "goimports", "gofmt" },
      rust = { "rustfmt" },
    },

    formatters = {
      stylua = {
        prepend_args = { "--column-width", "80" },
      },
      black = {
        prepend_args = { "--line-length", "80" },
      },
      isort = {
        prepend_args = { "--line-length", "80" },
      },
      prettier = {
        prepend_args = { "--print-width", "80" },
      },
      gofmt = {
        prepend_args = { "--textwidth", "80" },
      },
      goimports = {
        prepend_args = { "--textwidth", "80" },
      },
      rustfmt = {
        prepend_args = { "--config", "max_width=80" },
      },
    },

    -- Auto-format on save
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}
