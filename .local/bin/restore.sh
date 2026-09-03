#!/usr/bin/env bash
# restore.sh – fresh Omarchy post-install restore (target hostname: sky).
# Usage: restore.sh [backup-dir]
#   backup-dir defaults to the script's own dir if it holds pkglist-native.txt,
#   else ~/Mount/USB/backup-omarchy.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${1:-}/pkglist-native.txt" ]; then
    SRC="$1"
elif [ -f "$SCRIPT_DIR/pkglist-native.txt" ]; then
    SRC="$SCRIPT_DIR"
else
    SRC="$HOME/Mount/USB/backup-omarchy"
fi
echo "Backup source: $SRC"
[ -f "$SRC/pkglist-native.txt" ] || { echo "ERROR: no pkglist-native.txt in $SRC"; exit 1; }

echo "== [1/6] hostname -> sky =="
sudo hostnamectl set-hostname sky
sudo sed -i 's/^127.0.0.1.*/127.0.0.1\tlocalhost sky/' /etc/hosts
echo "== [2/6] secrets/keys/ssh =="
cp "$SRC/.secrets" ~/ 2>/dev/null || true; chmod 600 ~/.secrets
mkdir -p ~/.ssh && cp -a "$SRC/.ssh/." ~/.ssh/ 2>/dev/null || true; chmod 700 ~/.ssh; chmod 600 ~/.ssh/id_* 2>/dev/null || true
cp -a "$SRC/.gnupg" ~/ 2>/dev/null || true; cp "$SRC/.claude.json" ~/ 2>/dev/null || true
cp "$SRC/agent-notify.conf" "$SRC/telegram-notify.conf" ~/ 2>/dev/null || true
mkdir -p ~/.config && cp -a "$SRC/openvpn" ~/.config/ 2>/dev/null || true
echo "== [3/6] dotfiles bootstrap =="
export PATH="$HOME/.local/bin:$PATH"
if [ -d "$HOME/.dotfiles" ]; then
    bash "$HOME/.local/bin/bootstrap.sh"
else
    git clone --bare git@github.com:denialbb/.dotfiles.git "$HOME/.dotfiles"
    /usr/bin/git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
    /usr/bin/git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout || true
    bash "$HOME/.local/bin/bootstrap.sh"
fi
echo "== [4/6] pkglist =="
sudo pacman -S --needed --noconfirm - < "$SRC/pkglist-native.txt" || true
yay -S --needed --noconfirm - < "$SRC/pkglist-aur.txt" || true
echo "== [5/6] app configs from backup (opencode/pi/herdr/nom/agy/browser) =="
mkdir -p ~/.config/opencode ~/.pi/agent ~/.config/herdr ~/.config/nom ~/.gemini/antigravity-cli ~/.config/qutebrowser
cp -a "$SRC/.config/opencode/." ~/.config/opencode/ 2>/dev/null || true
cp "$SRC/.pi/agent/settings.json" ~/.pi/agent/ 2>/dev/null || true; cp -a "$SRC/.pi/agent/extensions/." ~/.pi/agent/extensions/ 2>/dev/null || true
cp "$SRC/.config/herdr/config.toml" ~/.config/herdr/ 2>/dev/null || true
cp "$SRC/.config/nom/config.yml" ~/.config/nom/ 2>/dev/null || true
cp "$SRC/.gemini/antigravity-cli/settings.json" ~/.gemini/antigravity-cli/ 2>/dev/null || true
cp "$SRC/qutebrowser/bookmarks" "$SRC/qutebrowser/quickmarks" ~/.config/qutebrowser/ 2>/dev/null || true
cp "$SRC/chromium-backup/Bookmarks"* ~/.config/chromium/Default/ 2>/dev/null || true
echo "NOTE: Chromium 'Login Data' is keyring-encrypted; copy manually: cp $SRC/chromium-backup/'Login Data' ~/.config/chromium/Default/ then unlock GNOME keyring once."
cp "$SRC/nom.db" ~/.config/nom/nom.db 2>/dev/null || true
echo "== [6/6] projects =="
mkdir -p ~/Projects && for r in agent-skills ai-tooling kobo-notes pi-extensions limen r-edit AEGIS aoc2019; do [ -d ~/Projects/$r ] || git clone git@github.com:denialbb/$r.git ~/Projects/$r 2>/dev/null || true; done
echo "DONE. Reboot, then: omarchy theme set firesky"
