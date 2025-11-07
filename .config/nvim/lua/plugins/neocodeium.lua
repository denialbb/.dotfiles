return {
  "monkoose/neocodeium",
  event = "VeryLazy",
  config = function()
    local neocodeium = require("neocodeium")
    neocodeium.setup()
    vim.keymap.set("i", "<C-Tab>", neocodeium.accept)
    vim.keymap.set("i", "<A-Tab>", neocodeium.accept_line)
  end,
}
