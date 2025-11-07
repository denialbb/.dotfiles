return {
  "saghen/blink.cmp",
  opts = {
    menu = {
      direction_priority = function()
        local ctx = require("blink.cmp").get_context()
        local item = require("blink.cmp").get_selected_item()
        if ctx == nil or item == nil then
          return { "s", "n" }
        end

        local item_text = item.textEdit ~= nil and item.textEdit.newText
          or item.insertText
          or item.label
        local is_multi_line = item_text:find("\n") ~= nil

        -- after showing the menu upwards, we want to maintain that direction
        -- until we re-open the menu, so store the context id in a global variable
        if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
          vim.g.blink_cmp_upwards_ctx_id = ctx.id
          return { "n", "s" }
        end
        return { "s", "n" }
      end,
      completion = {
        menu = {
          auto_show = function(ctx)
            return ctx.mode ~= "default"
          end,
        },
      },
    },
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
