# Thank you Bread for the config!
from pathlib import Path
import sys

# Add the directory containing colors.py to Python's path
config_dir = Path("~/.config/qutebrowser").expanduser().resolve()
sys.path.insert(0, str(config_dir))

import omarchy

# pylint: disable=C0111
c = c  # noqa: F821 pylint: disable=E0602,C0103
config = config  # noqa: F821 pylint: disable=E0602,C0103
startpage = "file:///home/dnbias/.config/qutebrowser/startpage/index.html"

# pylint settings included to disable linting errors

# import subprocess

# def read_xresources(prefix):
#     props = {}
#     x = subprocess.run(
#         ["xrdb", "-query"], capture_output=True, check=True, text=True
#     )
#     lines = x.stdout.split("\n")
#     for line in filter(lambda l: l.startswith(prefix), lines):
#         prop, _, value = line.partition(":\t")
#         props[prop] = value
#     return props


# xresources = read_xresources("*")
theme = omarchy.read_omarchy_theme("colors")

c.colors.statusbar.normal.bg = theme["primary.background"]
c.colors.statusbar.command.bg = theme["primary.background"]
c.colors.statusbar.command.fg = theme["primary.foreground"]
c.colors.statusbar.normal.fg = theme["primary.foreground"]
c.colors.statusbar.passthrough.fg = theme["normal.green"]
c.colors.statusbar.url.fg = theme["normal.green"]
c.colors.statusbar.url.success.https.fg = theme["normal.green"]
c.colors.statusbar.url.hover.fg = theme["bright.green"]
c.statusbar.show = "always"
c.colors.tabs.even.bg = "#000000"  # transparent tabs!!
c.colors.tabs.odd.bg = "#000000"
c.colors.tabs.bar.bg = "#000000"
# c.colors.tabs.even.bg = theme["primary.background"]
# c.colors.tabs.odd.bg = theme["primary.background"]
# c.colors.tabs.bar.bg = theme["primary.background"]
c.colors.tabs.even.fg = theme["normal.blue"]
c.colors.tabs.odd.fg = theme["normal.blue"]
c.colors.tabs.selected.even.bg = theme["primary.background"]
c.colors.tabs.selected.odd.bg = theme["primary.background"]
c.colors.tabs.selected.even.fg = theme["normal.green"]
c.colors.tabs.selected.odd.fg = theme["normal.green"]
c.colors.hints.bg = theme["primary.background"]
c.colors.hints.fg = theme["primary.foreground"]
c.tabs.show = "multiple"

c.colors.completion.item.selected.match.fg = theme["normal.blue"]
c.colors.completion.match.fg = theme["normal.yellow"]

c.colors.tabs.indicator.start = theme["normal.blue"]
c.colors.tabs.indicator.stop = theme["normal.cyan"]
c.colors.completion.odd.bg = theme["primary.background"]
c.colors.completion.even.bg = theme["primary.background"]
c.colors.completion.fg = theme["primary.foreground"]
c.colors.completion.category.bg = theme["primary.background"]
c.colors.completion.category.fg = theme["primary.foreground"]
c.colors.completion.item.selected.bg = theme["primary.background"]
c.colors.completion.item.selected.fg = theme["primary.foreground"]

c.colors.messages.info.bg = theme["primary.background"]
c.colors.messages.info.fg = theme["primary.foreground"]
c.colors.messages.error.bg = theme["primary.background"]
c.colors.messages.error.fg = theme["primary.foreground"]
c.colors.downloads.error.bg = theme["primary.background"]
c.colors.downloads.error.fg = theme["primary.foreground"]

c.colors.downloads.bar.bg = theme["primary.background"]
c.colors.downloads.start.bg = theme["normal.blue"]
c.colors.downloads.start.fg = theme["primary.foreground"]
c.colors.downloads.stop.bg = theme["normal.red"]
c.colors.downloads.stop.fg = theme["primary.foreground"]

c.colors.tooltip.bg = theme["primary.background"]
c.colors.webpage.bg = theme["primary.background"]
c.hints.border = theme["primary.foreground"]

c.colors.contextmenu.menu.bg = theme["primary.background"]
c.colors.contextmenu.menu.fg = theme["primary.foreground"]
c.colors.keyhint.bg = theme["primary.background"]
c.colors.keyhint.fg = theme["primary.foreground"]

c.url.start_pages = startpage
c.url.default_page = startpage

c.tabs.title.format = "{audio}{current_title}"
c.fonts.web.size.default = 20

c.url.searchengines = {
    # note - if you use duckduckgo, you can make use of its built in bangs, of which there are many! https://duckduckgo.com/bangs
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "!aw": "https://wiki.archlinux.org/?search={}",
    "!apkg": "https://archlinux.org/packages/?sort=&q={}&maintainer=&flagged=",
    "!gh": "https://github.com/search?o=desc&q={}&s=stars",
    "!yt": "https://www.youtube.com/results?search_query={}",
}

c.completion.open_categories = [
    "searchengines",
    "quickmarks",
    "bookmarks",
    "history",
    "filesystem",
]

config.load_autoconfig()  # load settings done via the gui

c.auto_save.session = False  # save tabs on quit/restart
c.spellcheck.languages = ["en-US", "it-IT"]

# keybinding changes
config.bind("=", "cmd-set-text -s :open")
config.bind("h", "history")
config.bind("cc", 'hint images spawn sh -c "cliphist link {hint-url}"')
config.bind("cs", "cmd-set-text -s :config-source")
config.bind("tH", "config-cycle tabs.show multiple never")
config.bind("sH", "config-cycle statusbar.show always never")
config.bind("T", "hint links tab")
config.bind("pP", "open -- {primary}")
config.bind("pp", "open -- {clipboard}")
config.bind("pt", "open -t -- {clipboard}")
config.bind("qm", "macro-record")
config.bind("<ctrl-y>", "spawn --userscript ytdl.sh")
config.bind("tT", "config-cycle tabs.position bottom left")
config.bind("gJ", "tab-move +")
config.bind("gK", "tab-move -")
config.bind("gm", "tab-move")

# dark mode setup
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = "lightness-cielab"
c.colors.webpage.darkmode.policy.images = "never"
c.colors.webpage.bg = theme["primary.background"]
config.set("colors.webpage.darkmode.enabled", False, "file://*")

# styles, cosmetics
c.content.user_stylesheets = [
    "~/.config/qutebrowser/styles/youtube-tweaks.css",
    "~/.config/qutebrowser/styles/reddit-tweaks.css",
]
c.tabs.padding = {"top": 5, "bottom": 5, "left": 9, "right": 9}
c.tabs.indicator.width = 0  # no tab indicators
# c.window.transparent = True # apparently not needed
c.tabs.width = "7%"
c.tabs.position = "bottom"
c.tabs.title.alignment = "center"
c.scrolling.smooth = True

# fonts
c.fonts.default_family = ["agave", "Anonymice Nerd Font", "Geist Mono NFM"]
c.fonts.default_size = "12pt"
c.fonts.web.family.fixed = "monospace"
c.fonts.web.family.sans_serif = "monospace"
c.fonts.web.family.serif = "monospace"
c.fonts.web.family.standard = "monospace"

# privacy - adjust these settings based on your preference
# config.set("completion.cmd_history_max_items", 0)
# config.set("content.private_browsing", True)
config.set("content.webgl", False, "*")
config.set("content.canvas_reading", False)
config.set("content.geolocation", False)
config.set("content.webrtc_ip_handling_policy", "default-public-interface-only")
config.set("content.cookies.accept", "all")
config.set("content.cookies.store", True)
# config.set("content.javascript.enabled", False) # tsh keybind to toggle

# Adblocking info -->
# For yt ads: place the greasemonkey script yt-ads.js in your greasemonkey folder (~/.config/qutebrowser/greasemonkey).
# The script skips through the entire ad, so all you have to do is click the skip button.
# Yeah it's not ublock origin, but if you want a minimal browser, this is a solution for the tradeoff.
# You can also watch yt vids directly in mpv, see qutebrowser FAQ for how to do that.
# If you want additional blocklists, you can get the python-adblock package, or you can uncomment the ublock lists here.
c.content.blocking.enabled = True
# c.content.blocking.method = 'adblock' # uncomment this if you install python-adblock
# c.content.blocking.adblock.lists = [
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2022.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2023.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2024.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-cookies.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-others.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
#     "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt",
# ]
