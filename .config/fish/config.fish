# Basic shell settings
if status is-interactive
    # Commands to run in interactive sessions can go here

    set fish_greeting '' # Disable welcome message

    # Initialize starship (prompt)
    if command -q starship
        starship init fish | source
    end

    # Initialize zoxide (smart cd)
    if command -q zoxide
        zoxide init fish | source
    end

    # Initialize mise (version manager)
    if command -q mise
        mise activate fish | source
    end

    # Initialize cargo
    source "$HOME/.local/share/cargo/env.fish"

    # Export important environment variables
    export PATH="$PATH:~/.config/emacs/bin:~/.local/bin:$HOME/.local/bin"
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
    export BROWSER="librewolf"
    export ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"

    # Source user's personal Fish configuration
    for file in ~/.config/fish/user/*.fish
        if test -f $file
            source $file
        end
    end 2>/dev/null

    # Tmux auto-attach if not already in a pane
    if status is-interactive
        and not set -q TMUX
        and command -q tmux
        exec tmux new -A -s main
    end

    # Add fzf shell integration for inline completion on CTRL+T
    if command -q fzf
        fzf --fish | source
    end

else
    # Non-interactive commands
    # For example, this runs mise activate for scripts that use it
    if command -q mise
        mise activate fish | source
    end
end
