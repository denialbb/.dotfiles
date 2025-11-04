return {
  "folke/zen-mode.nvim",
  opts = {
    window = {
      backdrop = 0.95,
      width = 80,
    },
    plugins = {
      options = { enabled = true },
      gitsigns = { enabled = false },
      tmux = { enabled = false },
    },
    on_open = function()
      vim.o.showtabline = 0
      vim.o.cmdheight = 0
    end,
    on_close = function()
      vim.o.showtabline = 0
      vim.o.cmdheight = 0
    end,
  },
  keys = {
    { "<leader>z", "<cmd>ZenMode<cr>", desc = "Toggle Zen Mode" },
  },
}
