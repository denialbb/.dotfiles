if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source
zoxide init fish | source
mise activate fish | source

export PATH="$PATH:~/.config/emacs/bin"
export PATH="$PATH:~/.local/bin"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
export BROWSER="zen-browser"
set fish_greeting ''

for f in ~/.config/fish/user/*.fish
    source $f
end
