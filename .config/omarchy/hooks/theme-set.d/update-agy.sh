#!/bin/bash
# Sync Omarchy theme palette into Antigravity CLI (AGY) state

python3 - << 'PY_EOF'
import os
import re
import tomllib

home = os.path.expanduser("~")
colors_path = os.path.join(home, ".local/state/omarchy/current/theme/colors.toml")
pbtxt_path = os.path.join(home, ".gemini/antigravity-cli/jetski_state.pbtxt")

if not os.path.exists(colors_path) or not os.path.exists(pbtxt_path):
    exit(0)

try:
    with open(colors_path, "rb") as f:
        c = tomllib.load(f)

    bg = c.get("background", "#080C09")
    primary = c.get("accent", "#3CBF5C")
    fg = c.get("foreground", "#8BC98C")
    bright_fg = c.get("bright_foreground", "#C5E6C6")
    is_light = c.get("mode") == "light"
    mode_str = "THEME_MODE_LIGHT" if is_light else "THEME_MODE_DARK"
    seed_field = "custom_theme_seeds_light" if is_light else "custom_theme_seeds_dark"

    with open(pbtxt_path, "r", encoding="utf-8") as f:
        content = f.read()

    content = re.sub(r"theme_mode:\s*\w+\n?", "", content)
    content = re.sub(r"custom_theme_seeds_\w+\s*\{[^}]*\}\n?", "", content)

    block = f"""theme_mode: {mode_str}
{seed_field}: {{
  background: "{bg}"
  primary: "{primary}"
  foreground_override: "{fg}"
  primary_foreground_override: "{bright_fg}"
}}
"""
    new_content = content.rstrip() + "\n" + block
    with open(pbtxt_path, "w", encoding="utf-8") as f:
        f.write(new_content)
except Exception as e:
    print(f"update-agy error: {e}")
PY_EOF
