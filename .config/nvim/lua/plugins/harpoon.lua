return {
  {
    "theprimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup()
    end,
    keys = {
      {
        "<leader>A",
        function()
          require("harpoon"):list():append()
        end,
        desc = "harpoon file",
      },
      {
        "<leader>a",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "harpoon quick menu",
      },
      {
        "<C-h>",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "harpoon to file 1",
      },
      {
        "<C-t>",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "harpoon to file 2",
      },
      {
        "<C-n>",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "harpoon to file 3",
      },
      {
        "<C-s>",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "harpoon to file 4",
      },
    },

    --   config = function()
    --     -- basic telescope configuration
    --     local conf = require("telescope.config").values
    --     local function toggle_telescope(harpoon_files)
    --       local file_paths = {}
    --       for _, item in ipairs(harpoon_files.items) do
    --         table.insert(file_paths, item.value)
    --       end
    --
    --       require("telescope.pickers")
    --         .new({}, {
    --           prompt_title = "Harpoon",
    --           finder = require("telescope.finders").new_table({
    --             results = file_paths,
    --           }),
    --           previewer = conf.file_previewer({}),
    --           sorter = conf.generic_sorter({}),
    --         })
    --         :find()
    --     end
    --   end,
    --   vim.keymap.set("n", "<C-e>", function()
    --     toggle_telescope(harpoon:list())
    --   end, { desc = "Open harpoon window" }),
  },
}
