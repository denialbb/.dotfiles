-- Extra autostart processes.
-- o.launch_on_start("my-service")

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor oreo_white_cursors 14")
end)
