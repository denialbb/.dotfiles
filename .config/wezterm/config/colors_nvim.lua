local wezterm = require("wezterm")
local config = require("config")
local file = io.open(wezterm.config_dir .. "/colorscheme", "r")
if file then
	config.color_scheme = file:read("*a")
	file:close()
else
	config.color_scheme = "Tokyo Night Day"
end
