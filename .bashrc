# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

. "$HOME/.local/share/../bin/env.sh"

# Book & Article servers
alias start-articles='systemctl --user start articles-server.service'
alias stop-articles='systemctl --user stop articles-server.service'
alias restart-articles='systemctl --user restart articles-server.service'
alias status-articles='systemctl --user status articles-server.service'

alias start-calibre='systemctl --user start calibre-server.service'
alias stop-calibre='systemctl --user stop calibre-server.service'
alias restart-calibre='systemctl --user restart calibre-server.service'
alias status-calibre='systemctl --user status calibre-server.service'

. "$HOME/.cargo/env"
