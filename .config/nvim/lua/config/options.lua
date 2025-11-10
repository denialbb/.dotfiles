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
opt.textwidth = 80

-- vim.o.autochdir = true -- breaks harpoon
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.termguicolors = true
o.ignorecase = true
o.infercase = true
o.smartcase = true
o.wrap = true
o.cursorline = false
o.scrolloff = 6
opt.wrap = true -- Enable soft wrapping
opt.linebreak = true -- Break at word boundaries
opt.breakindent = true -- Indent wrapped lines
opt.breakindentopt = "shift:4" -- Indent by 2 extra spaces
opt.showbreak = "↳ " -- Visual indicator for wrapped lines
opt.textwidth = 80 -- Hard-wrap guide
opt.colorcolumn = "80" -- Visual column
