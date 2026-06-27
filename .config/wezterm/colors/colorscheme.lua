local theme = require("wezterm").colors.theme
local colorscheme = {
	foreground = theme.foreground,
	background = theme.background,
	cursor_bg = theme.cursor_bg,
	cursor_border = theme.cursor_border,
	cursor_fg = theme.cursor_fg,
	selection_bg = theme.selection_bg,
	selection_fg = theme.selection_fg,
	ansi = {
		"#0C0C0C", -- black
		"#C50F1F", -- red
		"#13A10E", -- green
		"#C19C00", -- yellow
		"#0037DA", -- blue
		"#881798", -- magenta/purple
		"#3A96DD", -- cyan
		"#CCCCCC", -- white
	},
	brights = {
		"#767676", -- black
		"#E74856", -- red
		"#16C60C", -- green
		"#F9F1A5", -- yellow
		"#3B78FF", -- blue
		"#B4009E", -- magenta/purple
		"#61D6D6", -- cyan
		"#F2F2F2", -- white
	},
	tab_bar = {
		background = "rgba(0, 0, 0, 0.4)",
		active_tab = {
			bg_color = theme.surface2,
			fg_color = theme.text,
		},
		inactive_tab = {
			bg_color = theme.surface0,
			fg_color = theme.subtext1,
		},
		inactive_tab_hover = {
			bg_color = theme.surface0,
			fg_color = theme.text,
		},
		new_tab = {
			bg_color = theme.base,
			fg_color = theme.text,
		},
		new_tab_hover = {
			bg_color = theme.mantle,
			fg_color = theme.text,
			italic = true,
		},
	},
	visual_bell = theme.red,
	indexed = {
		[16] = theme.peach,
		[17] = theme.rosewater,
	},
	scrollbar_thumb = theme.surface2,
	split = theme.overlay0,
	compose_cursor = theme.flamingo,
}

return colorscheme
