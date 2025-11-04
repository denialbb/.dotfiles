local platform = require("utils.platform")

local options = {
	-- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
	ssh_domains = {},

	-- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
	unix_domains = {},

	-- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
	wsl_domains = {},
}

if platform.is_win then
	options.ssh_domains = {
		{},
	}

	options.wsl_domains = {
		{},
		{},
	}
end

return options
