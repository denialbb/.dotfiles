#!/usr/bin/env python3
import os
import json
import tomllib

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    if len(hex_str) == 3:
        hex_str = ''.join(c*2 for c in hex_str)
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(rgb):
    return '#' + ''.join(f'{val:02x}' for val in rgb)

def blend_colors(hex1, hex2, weight):
    r1, g1, b1 = hex_to_rgb(hex1)
    r2, g2, b2 = hex_to_rgb(hex2)
    r = int(r1 * (1 - weight) + r2 * weight)
    g = int(g1 * (1 - weight) + g2 * weight)
    b = int(b1 * (1 - weight) + b2 * weight)
    return rgb_to_hex((r, g, b))

def main():
    home = os.path.expanduser('~')
    alacritty_path = os.path.join(home, '.config/omarchy/current/theme/alacritty.toml')
    
    # Defaults
    bg = "#101010"
    fg = "#d4d4d4"
    red = "#ff8080"
    green = "#99ffe4"
    yellow = "#ffc799"
    blue = "#a0a0a0"
    magenta = "#ffcfa8"
    cyan = "#99ffe4"
    bright_black = "#505050"
    accent = "#ffcfa8"
    selected_bg = "#232323"
    
    if os.path.exists(alacritty_path):
        try:
            with open(alacritty_path, 'rb') as f:
                data = tomllib.load(f)
            
            colors = data.get('colors', {})
            primary = colors.get('primary', {})
            bg = primary.get('background', bg)
            fg = primary.get('foreground', fg)
            
            normal = colors.get('normal', {})
            red = normal.get('red', red)
            green = normal.get('green', green)
            yellow = normal.get('yellow', yellow)
            blue = normal.get('blue', blue)
            magenta = normal.get('magenta', magenta)
            cyan = normal.get('cyan', cyan)
            
            bright = colors.get('bright', {})
            bright_black = bright.get('black', bright_black)
            
            cursor = colors.get('cursor', {})
            accent = cursor.get('cursor', magenta)
            
            selection = colors.get('selection', {})
            selected_bg = selection.get('background', selected_bg)
        except Exception as e:
            print(f"Error parsing alacritty.toml: {e}")
            
    # Calculate derived colors
    user_msg_bg = blend_colors(bg, fg, 0.08)
    custom_msg_bg = blend_colors(bg, fg, 0.05)
    tool_pending_bg = blend_colors(bg, fg, 0.04)
    tool_success_bg = blend_colors(bg, green, 0.08)
    tool_error_bg = blend_colors(bg, red, 0.08)
    
    muted = blend_colors(fg, bg, 0.4)
    dim = blend_colors(fg, bg, 0.6)
    border_muted = blend_colors(bg, fg, 0.25)
    
    theme_data = {
        "$schema": "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json",
        "name": "omarchy",
        "vars": {
            "bg": bg,
            "fg": fg,
            "red": red,
            "green": green,
            "yellow": yellow,
            "blue": blue,
            "magenta": magenta,
            "cyan": cyan,
            "bright_black": bright_black,
            "accent": accent,
            "selectedBg": selected_bg,
            "userMsgBg": user_msg_bg,
            "customMsgBg": custom_msg_bg,
            "toolPendingBg": tool_pending_bg,
            "toolSuccessBg": tool_success_bg,
            "toolErrorBg": tool_error_bg,
            "muted": muted,
            "dim": dim,
            "borderMuted": border_muted
        },
        "colors": {
            "accent": "accent",
            "border": "blue",
            "borderAccent": "cyan",
            "borderMuted": "borderMuted",
            "success": "green",
            "error": "red",
            "warning": "yellow",
            "muted": "muted",
            "dim": "dim",
            "text": "fg",
            "thinkingText": "muted",

            "selectedBg": "selectedBg",
            "userMessageBg": "userMsgBg",
            "userMessageText": "fg",
            "customMessageBg": "customMsgBg",
            "customMessageText": "fg",
            "customMessageLabel": "magenta",
            "toolPendingBg": "toolPendingBg",
            "toolSuccessBg": "toolSuccessBg",
            "toolErrorBg": "toolErrorBg",
            "toolTitle": "fg",
            "toolOutput": "muted",

            "mdHeading": "yellow",
            "mdLink": "blue",
            "mdLinkUrl": "dim",
            "mdCode": "accent",
            "mdCodeBlock": "green",
            "mdCodeBlockBorder": "borderMuted",
            "mdQuote": "muted",
            "mdQuoteBorder": "borderMuted",
            "mdHr": "borderMuted",
            "mdListBullet": "accent",

            "toolDiffAdded": "green",
            "toolDiffRemoved": "red",
            "toolDiffContext": "muted",

            "syntaxComment": "dim",
            "syntaxKeyword": "blue",
            "syntaxFunction": "yellow",
            "syntaxVariable": "cyan",
            "syntaxString": "green",
            "syntaxNumber": "magenta",
            "syntaxType": "cyan",
            "syntaxOperator": "fg",
            "syntaxPunctuation": "fg",

            "thinkingOff": "borderMuted",
            "thinkingMinimal": "borderMuted",
            "thinkingLow": "blue",
            "thinkingMedium": "cyan",
            "thinkingHigh": "magenta",
            "thinkingXhigh": "accent",

            "bashMode": "green"
        },
        "export": {
            "pageBg": "bg",
            "cardBg": "userMsgBg",
            "infoBg": "toolPendingBg"
        }
    }
    
    # Ensure directory exists
    pi_themes_dir = os.path.join(home, '.pi/agent/themes')
    os.makedirs(pi_themes_dir, exist_ok=True)
    
    # Write theme file
    theme_file_path = os.path.join(pi_themes_dir, 'omarchy.json')
    with open(theme_file_path, 'w') as f:
        json.dump(theme_data, f, indent=2)
        
    print(f"Updated {theme_file_path}")

    # Ensure ~/.pi/agent/settings.json sets theme to 'omarchy'
    settings_path = os.path.join(home, '.pi/agent/settings.json')
    if os.path.exists(settings_path):
        try:
            with open(settings_path, 'r') as f:
                settings = json.load(f)
            if settings.get('theme') != 'omarchy':
                settings['theme'] = 'omarchy'
                with open(settings_path, 'w') as f:
                    json.dump(settings, f, indent=2)
                print("Updated settings.json theme to 'omarchy'")
        except Exception as e:
            print(f"Error updating settings.json: {e}")

if __name__ == '__main__':
    main()
