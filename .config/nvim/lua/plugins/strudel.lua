return {
  "gruvw/strudel.nvim",
  build = "npm install",
  config = function()
    require("strudel").setup({
      ui = {
        maximise_menu_panel = true,
        hide_menu_panel = false,
        hide_top_bar = false,
        hide_code_editor = false,
        hide_error_display = false,
      },
      update_on_save = false,
      sync_cursor = true,
      report_eval_errors = true,
      -- custom_css_file = "/path/to/your/custom.css",
      headless = false,
      -- Path to the directory where Strudel browser user data (cookies, sessions, etc.) is stored
      -- browser_data_dir = "~/.cache/strudel-nvim/",
      -- Absolute path to a (chromium based) browser executable of choice
      -- browser_exec_path = "/absolute/path/to/browser/executable",
    })
  end,
}
