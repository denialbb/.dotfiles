if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting ''

starship init fish | source
zoxide init fish | source
mise activate fish | source

export PATH="$PATH:~/.config/emacs/bin"
export PATH="$PATH:~/.local/bin"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
export BROWSER="librewolf"

export ZELLIJ_CONFIG_DIR=$HOME/.config/zellij

# Check if our Terminal emulator is Ghostty
if [ "$TERM" = xterm-ghostty ]
    # Launch zellij
    eval (zellij setup --generate-auto-start fish | string collect)
end

for f in ~/.config/fish/user/*.fish
    source $f
end
