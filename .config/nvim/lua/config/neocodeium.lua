local neocodeium = require("neocodeium")
local blink = require("blink.cmp")

vim.api.nvim_create_autocmd("User", {
  pattern = "BlinkCmpMenuOpen",
  callback = function()
    neocodeium.clear()
  end,
})

neocodeium.setup({
  filter = function()
    return not blink.is_visible()
  end,
})
