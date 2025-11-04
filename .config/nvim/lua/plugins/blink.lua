return {
  "saghen/blink.cmp",
  opts = {
    completion = {
      accept = { auto_select = false },
      trigger = {
        prefetch_on_insert = false,
        show_on_insert = false,
      },
    },
    keymap = {
      ["<C-Space>"] = { "show", "fallback" }, -- manual trigger
    },
  },
}
