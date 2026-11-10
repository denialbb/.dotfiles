-- Hyprland keybindings added by omarchy-keepassxc
-- Replaces the default 1Password binding with KeePassXC.
-- Sourced from hyprland.lua by install.sh.

-- Unbind 1Password binding
hl.unbind("SUPER + SHIFT + SLASH")

-- KeePassXC: launch or focus
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "keepassxc", focus = "^keepassxc$" })

-- Open KeePassXC on workspace 5 (at login and whenever it starts).
-- "silent" = move it there without switching the active workspace, so the
-- autostarted instance at login does not steal focus.
o.window("^[Kk]ee[Pp]ass[Xx][Cc]$", { workspace = "5 silent" })
