-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- udiskie is supervised by systemd (udiskie.service) with tray support.
-- Suppress omarchy's default autostart udiskie invocation (--no-tray).
local orig_launch = o.launch
function o.launch(command)
  if type(command) == "string" and command:match("^udiskie") then
    return "true"
  end
  return orig_launch(command)
end

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor oreo_white_cursors 20")
end)

-- omarchy-keepassxc: start KeePassXC at login
o.launch_on_start("keepassxc")
