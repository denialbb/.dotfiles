#!/usr/bin/env python3
import os
import json
import subprocess
import urllib.request

def main():
    try:
        result = subprocess.run(["omarchy", "theme", "current"], capture_output=True, text=True, check=True)
        theme_name = result.stdout.strip()
    except Exception as e:
        print(f"Error getting Omarchy theme: {e}")
        return

    theme_key = theme_name.lower().replace(" ", "_").replace("-", "_")
    print(f"Current Omarchy theme: {theme_name} (key: {theme_key})")

    theme_mappings = {
        "catppuccin": {
            "obsidian_name": "Catppuccin",
            "repo": "catppuccin/obsidian",
            "mode": "dark"
        },
        "catppuccin_latte": {
            "obsidian_name": "Catppuccin",
            "repo": "catppuccin/obsidian",
            "mode": "light"
        },
        "tokyo_night": {
            "obsidian_name": "Tokyo Night",
            "repo": "tcmmichaelb139/obsidian-tokyonight",
            "mode": "dark"
        },
        "rose_pine": {
            "obsidian_name": "Rosé Pine",
            "repo": "rose-pine/obsidian",
            "mode": "dark"
        },
        "gruvbox": {
            "obsidian_name": "Gruvbox",
            "repo": "insign/obsidian-gruvbox",
            "mode": "dark"
        },
        "nord": {
            "obsidian_name": "Nord",
            "repo": "arcticicestudio/nord-obsidian",
            "mode": "dark"
        },
        "everforest": {
            "obsidian_name": "Everforest",
            "repo": "sarakusha/obsidian-everforest",
            "mode": "dark"
        },
        "kanagawa": {
            "obsidian_name": "Kanagawa",
            "repo": "crDraft/obsidian-kanagawa",
            "mode": "dark"
        }
    }

    mapping = theme_mappings.get(theme_key)
    if not mapping:
        print(f"No mapping found for theme '{theme_name}'. Falling back to default Obsidian theme.")
        obsidian_name = ""
        mode = "dark"
        repo = None
    else:
        obsidian_name = mapping["obsidian_name"]
        repo = mapping["repo"]
        mode = mapping.get("mode", "dark")

    vault_path = "/home/denial/Documents/Obsidian/zettelkasten"
    
    if repo:
        theme_dir = os.path.join(vault_path, ".obsidian", "themes", obsidian_name)
        theme_css_path = os.path.join(theme_dir, "theme.css")
        theme_manifest_path = os.path.join(theme_dir, "manifest.json")
        
        if not os.path.exists(theme_css_path) or not os.path.exists(theme_manifest_path):
            os.makedirs(theme_dir, exist_ok=True)
            branches = ["main", "master"]
            files = ["theme.css", "manifest.json"]
            download_success = True
            
            for f in files:
                downloaded = False
                for b in branches:
                    url = f"https://raw.githubusercontent.com/{repo}/{b}/{f}"
                    dest = os.path.join(theme_dir, f)
                    try:
                        print(f"Downloading {f} from {repo} ({b})...")
                        urllib.request.urlretrieve(url, dest)
                        downloaded = True
                        break
                    except Exception:
                        pass
                if not downloaded:
                    print(f"Failed to download {f} for {obsidian_name}")
                    download_success = False
                    break
            
            if not download_success:
                print("Failed to download theme files. Clearing theme selection.")
                obsidian_name = ""

    app_path = os.path.join(vault_path, ".obsidian", "appearance.json")
    try:
        with open(app_path, "r") as f:
            app_data = json.load(f)
    except Exception:
        app_data = {}

    app_data["cssTheme"] = obsidian_name
    app_data["theme"] = "obsidian" if mode == "dark" else "moonstone"
    
    with open(app_path, "w") as f:
        json.dump(app_data, f, indent=2)
    print(f"Successfully updated Obsidian theme to '{obsidian_name}' ({mode} mode) in appearance.json")

if __name__ == "__main__":
    main()
