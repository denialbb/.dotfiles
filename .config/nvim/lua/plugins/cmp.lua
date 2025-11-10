return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-buffer",
    "saghen/blink.nvim", -- Fast snippets
    "saghen/blink-cmp", -- Connect to cmp
  },
  opts = {
    snippet = {
      expand = function(args)
        require("blink").expand(args.body)
      end,
    },
    sources = {
      { name = "nvim_lsp" },
      { name = "blink-cmp" },
      { name = "path" },
      { name = "buffer" },
    },
  },
}
