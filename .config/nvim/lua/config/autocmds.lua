-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- Auto-open mini.files when nvim is launched with a directory
-- Auto-open mini.files when launching with a directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if arg and (vim.fn.isdirectory(arg) == 1 or arg == ".") then
      require("mini.files").open(arg, false)
    end
  end,
  desc = "Auto-open mini.files on directory launch",
})
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("wezterm_colorscheme", {
    clear = true,
  }),
  callback = function(args)
    local colorschemes = {
      ["tokyonight-day"] = "Tokyo Night Day",
      ["tokyonight-storm"] = "Tokyo Night Storm",
      ["catppuccin-frappe"] = "Catppuccin Frappe",
      ["catppuccin-latte"] = "Catppuccin Latte",
      ["catppuccin-macchiato"] = "Catppuccin Macchiato",
      ["catppuccin-mocha"] = "Catppuccin Mocha",
      ["gruvbox"] = "GruvboxDark",
      ["gruvbox-material"] = "Gruvbox Material",
      ["dracula"] = "Dracula (Official)",
      ["vesper"] = "Vesper",
      -- add more color schemes here ...
    }
    local colorscheme = colorschemes[args.match]
    if not colorscheme then
      return
    end
    -- Write the colorscheme to a file
    local filename = vim.fn.expand("$XDG_CONFIG_HOME/wezterm/colorscheme")
    assert(type(filename) == "string")
    local file = io.open(filename, "w")
    assert(file)
    file:write(colorscheme)
    file:close()
    vim.notify(
      "Setting WezTerm color scheme to " .. colorscheme,
      vim.log.levels.INFO
    )
  end,
})
