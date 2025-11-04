return {
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    opts.completion = {
      autocomplete = false,
    }
    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      ["<C-Space>"] = require("cmp").mapping.complete(),
    })
  end,
}
