-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local o = vim.o
local opt = vim.opt

opt.relativenumber = true
opt.spelllang = { "en", "it" }
opt.listchars = {
  tab = "  ",
  trail = "~", -- Trailing spaces
}
opt.list = true

-- vim.o.autochdir = true -- breaks harpoon
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.termguicolors = true
o.ignorecase = true
o.infercase = true
o.smartcase = true
o.wrap = false
o.cursorline = false
o.scrolloff = 6
