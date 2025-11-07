-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set({ "n", "x" }, ";", ":")
vim.keymap.set({ "n", "x" }, ":", ";")
vim.keymap.set("n", "L", "vg_", { desc = "Select to end of line" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "scroll up and center" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "scroll down and center" })
vim.keymap.set("n", "{", "{zz", { desc = "scroll up and center" })
vim.keymap.set("n", "}", "}zz", { desc = "scroll down and center" })
vim.keymap.set("n", "n", "nzzzv", { desc = "keep cursor centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "keep cursor centered" })
vim.keymap.set(
  "n",
  "gd",
  ":Gvdiffsplit<CR>",
  { desc = "Git diff current file" }
)
vim.keymap.set(
  "n",
  "<leader>s",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Search And Replace The Word Under The Cursor" }
)
vim.keymap.set(
  "i",
  "<C-Space>",
  "<cmd>lua require('supermaven').complete()<CR>",
  { desc = "supermaven complete" }
)
vim.keymap.set(
  "n",
  "<leader>sc",
  "<cmd>lua require('supermaven').chat()<CR>",
  { desc = "supermaven chat", noremap = true, silent = true }
)
vim.keymap.set("n", "K", "vim.lsp.buf.hover", { desc = "lsp hover" })
