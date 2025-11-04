if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source
zoxide init fish | source
mise activate fish | source

export PATH="$PATH:~/.config/emacs/bin"
export PATH="$PATH:~/.local/bin"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
export FZF_DIRS="Documents,Projects,.config"
export FZF_DEFAULT_OPTS="--height 100% --margin 35%,30%
                         --info right --preview-window=up,hidden,20% 
                         --bind 'ctrl-p:toggle-preview'"
set fish_greeting ''

# File system
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

function cd
    if test (count $argv) -eq 0
        builtin cd ~
        return
    else if test -d "$argv[1]"
        builtin cd $argv
    else
        z $argv && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    end
end

function open
    xdg-open $argv >/dev/null 2>&1 &
end

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
alias d='docker'
alias r='rails'

function n
    if test (count $argv) -eq 0
        nvim .
    else
        nvim $argv
    end
end

alias update='sudo pacman -Syu'
alias pac='sudo pacman -Syu'

alias srcfish='source ~/.config/fish/config.fish'

function gc
    read -P (set_color yellow)"Commit message: "(set_color normal) msg
    if test -n "$msg"
        git commit -m msg
    end
end

function gpa
    read -P (set_color yellow)"Commit message: "(set_color normal) msg
    if test -n "$msg"
        git add .
        git commit -m msg
        git push
    end
end

alias man='batman'

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
alias gp='git push'
alias ga='git add '
alias gb='git branch '
alias gco='git checkout '
alias gd='git diff'
alias gs='git status'
alias gl='git log --oneline '
alias gll='git log '

alias rr='rm -rf'

# sudo last command
alias please='sudo !!'
alias uptime='uptime --pretty'
alias cat='bat --style=grid'
alias bat='bat --style=grid'
# copy with progress bar
alias cpv="rsync -ah --info=progress2"
alias systatus='systemctl status --system'

alias c='clear && ls'
alias home='cd ~/ && c'
alias ..='cd .. && c'
alias brain='cd ~/Documents/Zettelkasten/ && clear && ls --color=always | head -15'
alias new="ls -lt modified --color=always | head -15"

alias :q='exit'

alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
# .dotfiles bare git repository

function fe
    fzf -m --preview='bat -p --color=always {}' --bind 'enter:become(nvim {+})'
end

bind ctrl-f fe

function vpn
    sudo openvpn --config ~/.config/openvpn/us-free-5.protonvpn.udp.ovpn --auth-user-pass ~/.config/openvpn/pass.txt &
end
