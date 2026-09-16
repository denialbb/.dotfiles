#!/bin/bash
# Sync Omarchy theme into active tmux sessions

THEME_TMUX="$HOME/.local/state/omarchy/current/theme/tmux.conf"

if [[ -f "$THEME_TMUX" ]] && tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$THEME_TMUX" 2>/dev/null || true
    tmux refresh-client -S 2>/dev/null || true
fi
