from pathlib import Path
import os, re
from typing import Dict


def read_omarchy_theme(prefix: str = "") -> Dict[str, str]:
    """
    Parse ~/.config/omarchy/current/theme/alacritty.toml
    for the current omarchy color scheme
    """
    content = ""
    path = "~/.config/omarchy/current/theme/alacritty.toml"
    file = Path(path).expanduser()
    if file.exists():
        with open(file, "r") as f:
            content = f.read()
    else:
        return {}

    props = {}
    lines = content.splitlines()
    i = 0
    section_key = ""
    while i < len(lines):
        line = lines[i].strip()
        i += 1

        # Skip comments and empty lines
        if not line or line.startswith("#"):
            continue

        # Handle stanzas
        if "[" in line:
            section_key = str(re.findall(r"\[([^]]+)]", line)[0])

        # Basic parsing: "key = value" (ignore wildcards/bindings for simplicity)
        if "=" in line:
            key, value = line.split("=", 1)
            key = section_key + "." + key.strip()
            value = value.strip().strip("'").strip('"')

            # Apply prefix filter
            if prefix and not key.startswith(prefix):
                continue

            # Strip prefix from key (optional, for cleaner output)
            if prefix != "" and key.startswith(prefix):
                key = key[len(prefix) + 1 :]

            props[key] = value

    return props
