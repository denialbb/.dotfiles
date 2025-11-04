# File system
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias tree='tree -C'

# Tools
alias d='docker'
alias r='rails'

alias update='sudo pacman -Syu'
alias pac='sudo pacman -Syu'
# alias man='batman'

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
alias uptime='uptime --pretty'
alias cat='bat --style=grid'
alias bat='bat --style=grid'
# copy with progress bar
alias cpv="rsync -ah --info=progress2"
alias systatus='systemctl status --system'

alias c='clear'
alias home='cd ~/ && c'
alias ..='cd .. && c'
alias brain='cd ~/Documents/Zettelkasten/ && clear && ls --color=always | head -15'
alias new="ls -lt modified --color=always | head -15"
alias :q='exit'

# .dotfiles bare git repository
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
