return {
  desc = "Minimal, fast, distraction-free fuzzy finder",
  profile = "zen",
  winopts = {
    height = 0.38, -- Slightly smaller
    width = 0.55, -- Tighter fit
    row = 0.38, -- Centered vertically
    col = 0.50, -- Centered horizontally
    border = "none", -- No border
    preview = {
      layout = "vertical",
      vertical = "up:48%", -- Preview takes ~half
      hidden = "hidden", -- Start hidden (toggle with ?)
    },
  },
  fzf_opts = {
    ["--no-scrollbar"] = "",
    ["--info"] = "inline-right",
    ["--layout"] = "reverse",
    ["--border"] = "none",
    ["--pointer"] = ">",
    ["--marker"] = "•",
  },
  previewers = {
    builtin = {
      treesitter = false, -- Disable for speed
    },
  },
  keymap = {
    fzf = {
      ["ctrl-q"] = "select-all+accept",
      ["ctrl-/"] = "toggle-preview",
      ["ctrl-h"] = "toggle-preview-wrap",
    },
  },
}
