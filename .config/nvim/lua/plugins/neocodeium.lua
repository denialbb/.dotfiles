return {
  "monkoose/neocodeium",
  event = "InsertEnter",
  opts = {
    enabled = true,
    manual = false,
    virtual_text = {
      enabled = true,
      priority = 6000,
      filetypes = {
        rust = true,
        go = true,
        lua = true,
        python = true,
        javascript = true,
        typescript = true,
      },
      default_filetype_enabled = true,
    },

    keymaps = {
      accept = "<C-Tab>", -- Accept suggestion
      accept_line = "<A-Tab>", -- Accept suggestion
      reject = "<C-e>", -- Clear/reject
    },

    -- Filetype exclusions: Disable in non-code buffers
    filetypes = {
      enabled = true,
      disabled = {
        "gitcommit",
        "NeogitCommitMessage",
        "help",
        "markdown",
        "txt",
        "TelescopePrompt",
        "noice",
        "notify",
        "lazy",
      },
    },

    -- Other sane defaults
    show_status = true, -- Show status in lualine/winbar (if available)
    suggest = {
      min_triggers = 2, -- Start suggesting after 2 chars
    },
  },
  config = function(_, opts)
    local neocodeium = require("neocodeium")
    neocodeium.setup(opts)

    -- === FIXED: Only run cmp integration after cmp is loaded ===
    local group =
      vim.api.nvim_create_augroup("neocodeium_cmp", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      pattern = "CmpReady", -- LazyVim fires this when cmp is ready
      group = group,
      callback = function()
        local cmp = require("cmp")
        local cmp_open = false

        cmp.event:on("menu_opened", function()
          cmp_open = true
          neocodeium.cancel()
        end)

        cmp.event:on("menu_closed", function()
          cmp_open = false
        end)

        -- Optional: Auto-trigger NeoCodeium after cmp closes
        vim.api.nvim_create_autocmd("InsertEnter", {
          callback = function()
            if not cmp_open then
              neocodeium.complete()
            end
          end,
        })
      end,
    })
  end,
}
