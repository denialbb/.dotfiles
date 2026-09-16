#!/bin/bash
# Sync glow theme with active Omarchy theme

CURRENT_THEME_GLOW="$HOME/.local/state/omarchy/current/theme/glow.json"
GLOW_DIR="$HOME/.config/glow"
GLOW_CONFIG="$GLOW_DIR/glow.yml"
GLOW_STYLE="$GLOW_DIR/omarchy-theme.json"

if [[ -f "$CURRENT_THEME_GLOW" ]]; then
    mkdir -p "$GLOW_DIR"
    cp "$CURRENT_THEME_GLOW" "$GLOW_STYLE"
    
    if [[ -f "$GLOW_CONFIG" ]]; then
        if grep -q "^style:" "$GLOW_CONFIG"; then
            sed -i "s|^style:.*|style: \"$GLOW_STYLE\"|" "$GLOW_CONFIG"
        else
            echo "style: \"$GLOW_STYLE\"" >> "$GLOW_CONFIG"
        fi
    else
        echo "style: \"$GLOW_STYLE\"" > "$GLOW_CONFIG"
    fi
fi
