# fzf --fish | source

# Usage
# Ctrl+T -> Paste selected files/directories onto command line

# Preview file w/ bat
set -x FZF_CTRL_T_OPTS "
    --walker-skip .git,node_modules,target,.venv
    --preview 'bat -P -p --color=always {} --line-range=:250'
    --bind 'ctrl-/:change-preview-window(down|hidden)'
    --height=100%
"
export FZF_DIRS="Documents,Projects,.config"
set -x FZF_CTRL_F_OPTS "
    --height 100% --margin 35%,30%
    --info right --preview-window=up,hidden,20% 
    --bind 'ctrl-p:toggle-preview'
"
function fe
    fzf -m --preview='bat -p --color=always {}' --bind 'enter:become(nvim {+})'
end

bind ctrl-f fe
