#!/usr/bin/env python3
"""Sync Hunk diff viewer theme with the active Omarchy theme.

Mirrors update_pi_theme.py: reads the current theme's colors.toml and
writes a [themes.omarchy] custom theme into ~/.config/hunk/config.toml
(hunk custom-theme keys), selecting theme = "omarchy". Idempotent:
preserves all other hunk settings, only replaces the omarchy block.

Called from ~/.config/omarchy/hooks/theme-set (receives theme name as $1).
"""
import os
import re
import subprocess
import sys

try:
    import tomllib
except ImportError:
    import tomli as tomllib  # type: ignore[no-redef]


def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 3:
        hex_str = "".join(c * 2 for c in hex_str)
    return tuple(int(hex_str[i : i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#" + "".join(f"{v:02x}" for v in rgb)


def blend(bg, fg, weight):
    r1, g1, b1 = hex_to_rgb(bg)
    r2, g2, b2 = hex_to_rgb(fg)
    return rgb_to_hex(
        (
            int(r1 * (1 - weight) + r2 * weight),
            int(g1 * (1 - weight) + g2 * weight),
            int(b1 * (1 - weight) + b2 * weight),
        )
    )


def current_colors_path(theme_arg):
    home = os.path.expanduser("~")
    candidates = [
        os.path.join(home, ".local/state/omarchy/current/theme/colors.toml"),
        os.path.join(home, ".config/omarchy/current/theme/colors.toml"),
    ]
    for p in candidates:
        if os.path.exists(p):
            return p
    if theme_arg:
        try:
            out = subprocess.run(
                ["omarchy", "theme", "dir", theme_arg],
                capture_output=True,
                text=True,
                timeout=10,
            )
            d = out.stdout.strip().splitlines()
            if d:
                p = os.path.join(d[-1].strip(), "colors.toml")
                if os.path.exists(p):
                    return p
        except Exception as e:
            print(f"omarchy theme dir failed: {e}")
    return None


def main():
    theme_arg = sys.argv[1] if len(sys.argv) > 1 else None
    colors_path = current_colors_path(theme_arg)
    if not colors_path:
        print("No current Omarchy colors.toml found; skipping hunk theme sync.")
        return

    with open(colors_path, "rb") as f:
        c = tomllib.load(f)

    def get(*keys, default="#888888"):
        for k in keys:
            v = c.get(k)
            if isinstance(v, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", v):
                return v.lower()
        return default

    mode = c.get("mode", "dark")
    bg = get("background", default="#101010")
    fg = get("foreground", default="#d4d4d4")
    accent = get("accent", "cursor")
    muted = get("muted", "dark_foreground")
    panel = get("lighter_background", default=blend(bg, fg, 0.08))
    panel_alt = get("dark_background", "darker_background", default=blend(bg, fg, 0.04))
    selection = get("selection", "selection_background", default=blend(bg, accent, 0.25))
    green = get("green", "bright_green")
    red = get("red", "bright_red")
    yellow = get("yellow", "bright_yellow")
    blue = get("blue", "bright_blue")
    cyan = get("cyan", "bright_cyan")
    magenta = get("magenta", "bright_magenta")

    theme = {
        "base": "github-light-default" if mode == "light" else "tokyo-night",
        "label": "Omarchy",
        "background": bg,
        "panel": panel,
        "panelAlt": panel_alt,
        "border": muted,
        "accent": accent,
        "accentMuted": selection,
        "text": fg,
        "muted": muted,
        "addedBg": blend(bg, green, 0.20),
        "removedBg": blend(bg, red, 0.20),
        "movedAddedBg": blend(bg, yellow, 0.20),
        "movedRemovedBg": blend(bg, blue, 0.20),
        "contextBg": bg,
        "addedContentBg": blend(bg, green, 0.30),
        "removedContentBg": blend(bg, red, 0.30),
        "contextContentBg": panel_alt,
        "addedSignColor": green,
        "removedSignColor": red,
        "lineNumberBg": bg,
        "lineNumberFg": muted,
        "selectedHunk": selection,
        "badgeAdded": green,
        "badgeRemoved": red,
        "badgeNeutral": muted,
        "fileNew": green,
        "fileDeleted": red,
        "fileRenamed": yellow,
        "fileModified": blue,
        "fileUntracked": cyan,
        "noteBorder": muted,
        "noteBackground": panel,
        "noteTitleBackground": selection,
        "noteTitleText": fg,
    }
    syntax = {
        "default": get("light_foreground", "foreground"),
        "keyword": get("bright_green", "green"),
        "string": get("bright_yellow", "yellow"),
        "comment": muted,
        "number": get("orange", "yellow"),
        "function": get("bright_cyan", "cyan"),
        "property": get("cyan", "bright_cyan"),
        "type": get("bright_blue", "blue"),
        "variable": get("foreground", "light_foreground"),
        "operator": get("bright_magenta", "magenta"),
        "punctuation": get("dark_foreground", "muted"),
    }

    # syntax_scopes uses raw Shiki/TextMate scopes (same mapping hunk uses
    # for its legacy syntax roles). One table, no deprecation notice.
    scopes = {
        "default": ["source"],
        "keyword": ["keyword"],
        "string": ["string"],
        "comment": ["comment", "punctuation.definition.comment"],
        "number": ["constant.numeric"],
        "function": [
            "entity.name.function",
            "support.function",
            "variable.function",
        ],
        "property": ["variable.other.property", "support.variable.property"],
        "type": [
            "entity.name.type",
            "entity.name.class",
            "support.type",
            "support.class",
        ],
        "variable": ["variable"],
        "operator": ["keyword.operator"],
        "punctuation": ["punctuation"],
    }

    lines = ["[themes.omarchy]"]
    for k, v in theme.items():
        lines.append(f'{k} = "{v}"')
    lines.append("[themes.omarchy.syntax_scopes]")
    for role, color in syntax.items():
        for scope in scopes[role]:
            lines.append(f'"{scope}" = "{color}"')
    block = "\n".join(lines) + "\n"

    home = os.path.expanduser("~")
    config_path = os.path.join(home, ".config/hunk/config.toml")
    os.makedirs(os.path.dirname(config_path), exist_ok=True)
    current = ""
    if os.path.exists(config_path):
        with open(config_path) as f:
            current = f.read()

    # Drop any previous [themes.omarchy...] sections (incl. .syntax_scopes subsection).
    header_re = re.compile(r"^\s*\[\s*([^\]]+?)\s*\]\s*$")
    out = []
    skipping = False
    for line in current.splitlines(keepends=True):
        m = header_re.match(line)
        if m:
            table_name = m.group(1).strip().strip("\"'")
            if table_name == "themes.omarchy" or table_name.startswith("themes.omarchy."):
                skipping = True
                continue
            else:
                skipping = False
        if not skipping:
            out.append(line)

    # Separate root options from subsequent tables
    root_lines = []
    table_lines = []
    in_table = False
    for line in out:
        if not in_table and header_re.match(line):
            in_table = True
        if in_table:
            table_lines.append(line)
        else:
            root_lines.append(line)

    # Remove all existing root theme declarations to prevent duplicate key errors
    root_lines = [line for line in root_lines if not re.match(r"^\s*theme\s*=", line)]

    # Insert theme = "omarchy" after any initial comments/blank lines
    insert_idx = 0
    while insert_idx < len(root_lines) and (root_lines[insert_idx].strip().startswith("#") or not root_lines[insert_idx].strip()):
        insert_idx += 1
    root_lines.insert(insert_idx, 'theme = "omarchy"\n')

    root_text = "".join(root_lines).rstrip("\n")
    table_text = "".join(table_lines).strip("\n")

    parts = [root_text]
    if table_text:
        parts.append(table_text)
    parts.append(block.strip("\n"))

    new_config = "\n\n".join(p for p in parts if p) + "\n"

    # Validate TOML integrity before writing
    tomllib.loads(new_config)

    with open(config_path, "w") as f:
        f.write(new_config)
    print(f"Hunk theme synced from {colors_path} -> {config_path}")


if __name__ == "__main__":
    main()
