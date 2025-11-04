-- local colors = require("colors.custom")

return {
	max_fps = 120,
	front_end = "OpenGL", ---@type 'WebGpu' | 'OpenGL' | 'Software' -- WebGpu crashes Wayland
	webgpu_power_preference = "HighPerformance",
	-- webgpu_preferred_adapter = gpu_adapters:pick_manual('Dx12', 'IntegratedGpu'),
	-- webgpu_preferred_adapter = gpu_adapters:pick_manual('Gl', 'Other'),
	underline_thickness = "1.5pt",
	-- theme
	-- colors = colors, -- for loading the custom color scheme
	-- color_scheme = "Catppuccin Mocha",
	-- color_scheme = "Material (Gogh)",
	color_scheme = "MaterialOcean",

	-- cursor
	animation_fps = 120,
	cursor_blink_ease_in = "EaseOut",
	cursor_blink_ease_out = "EaseOut",
	default_cursor_style = "BlinkingBlock",
	cursor_blink_rate = 1000,

	enable_scroll_bar = false,

	-- tab bar
	enable_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = false,
	tab_max_width = 25,
	show_tab_index_in_tab_bar = false,
	switch_to_last_active_tab_when_closing_tab = true,

	-- command palette
	command_palette_fg_color = "#b4befe",
	command_palette_bg_color = "#11111b",
	command_palette_font_size = 12,
	command_palette_rows = 25,

	-- window
	window_padding = {
		left = 5,
		right = 2,
		top = 8,
		bottom = 0,
	},
	adjust_window_size_when_changing_font_size = false,
	window_close_confirmation = "NeverPrompt",
	window_frame = {
		active_titlebar_bg = "#090909",
		-- font = fonts.font,
		-- font_size = fonts.font_size,
	},
	-- inactive_pane_hsb = {
	--    saturation = 0.9,
	--    brightness = 0.65,
	-- },
	inactive_pane_hsb = {
		saturation = 1,
		brightness = 1,
	},

	visual_bell = {
		fade_in_function = "EaseIn",
		fade_in_duration_ms = 250,
		fade_out_function = "EaseOut",
		fade_out_duration_ms = 250,
		target = "CursorColor",
	},
}
