#!/usr/bin/env bash
# ==============================================================================
# Omarchy Post-Install & Dotfiles Bootstrap Script
# ==============================================================================
set -euo pipefail

DOTFILES_REPO="git@github.com:denialbb/.dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
NVIM_REPO="git@github.com:denialbb/nvim.git"
NVIM_DIR="$HOME/.config/nvim"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%s)"

echo "==> [1/7] Initializing Dotfiles Bare Repository..."
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning bare repository from $DOTFILES_REPO..."
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    echo "Dotfiles bare repository already exists at $DOTFILES_DIR."
fi

config() {
    /usr/bin/git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

# Ensure untracked files are hidden
config config --local status.showUntrackedFiles no

echo "==> [2/7] Checking out dotfiles working tree..."
if ! config checkout 2>/dev/null; then
    echo "Existing conflicting files detected. Backing them up to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    config checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | while IFS= read -r file; do
        if [ -e "$HOME/$file" ]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$file")"
            mv "$HOME/$file" "$BACKUP_DIR/$file"
        fi
    done
    config checkout
    echo "Conflicting files safely backed up to $BACKUP_DIR."
fi

# Ensure all scripts in ~/.local/bin are executable
if [ -d "$HOME/.local/bin" ]; then
    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
fi

echo "==> [3/7] Installing Native Arch Packages..."
if [ -f "$HOME/.config/pkglist-native.txt" ]; then
    echo "Installing native packages via pacman..."
    sudo pacman -S --needed --noconfirm - < "$HOME/.config/pkglist-native.txt"
fi

echo "==> [4/7] Installing AUR Packages..."
if ! command -v yay &>/dev/null; then
    echo "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    TEMP_YAY=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TEMP_YAY/yay"
    (cd "$TEMP_YAY/yay" && makepkg -si --noconfirm)
    rm -rf "$TEMP_YAY"
fi

if [ -f "$HOME/.config/pkglist-aur.txt" ]; then
    echo "Installing AUR packages via yay..."
    yay -S --needed --noconfirm - < "$HOME/.config/pkglist-aur.txt"
fi

echo "==> [5/7] Setting up Neovim Configuration..."
if [ ! -d "$NVIM_DIR" ]; then
    echo "Cloning nvim config from $NVIM_REPO..."
    git clone "$NVIM_REPO" "$NVIM_DIR"
elif [ ! -d "$NVIM_DIR/.git" ]; then
    echo "Directory $NVIM_DIR exists but is not a git repo. Backing up and cloning..."
    mv "$NVIM_DIR" "${NVIM_DIR}.bak.$(date +%s)"
    git clone "$NVIM_REPO" "$NVIM_DIR"
else
    echo "Nvim repository already present. Pulling latest..."
    git -C "$NVIM_DIR" pull --ff-only || true
fi

echo "==> [6/7] Restoring Mise Developer Runtimes..."
if command -v mise &>/dev/null && [ -f "$HOME/.config/mise/config.toml" ]; then
    echo "Running mise install..."
    mise install -y || true
fi

echo "==> [7/7] Enabling Systemd User Services..."
systemctl --user daemon-reload || true
USER_SERVICES=(
    "articles-server.service"
    "voxtype.service"
    "ydotoold.service"
    "swayosd-server.service"
    "elephant.service"
    "omarchy-recover-internal-monitor.service"
)

for svc in "${USER_SERVICES[@]}"; do
    if [ -f "$HOME/.config/systemd/user/$svc" ]; then
        echo "Enabling $svc..."
        systemctl --user enable --now "$svc" 2>/dev/null || echo "Warning: Failed to start $svc (binary may need additional configuration)."
    fi
done

echo ""
echo "=============================================================================="
echo " Bootstrap Complete! "
echo " Recommended next steps:"
echo "  1. Log out or restart your session (or reboot)."
echo "  2. Run 'omarchy theme set <theme-name>' to initialize active theme links."
echo "  3. Open fish shell and run 'fisher update' if using Fisher plugins."
echo "=============================================================================="

# Telegram notification if tg-send is configured
if command -v "$HOME/.local/bin/tg-send" &>/dev/null && [ -f "$HOME/.config/telegram-notify.conf" ]; then
    "$HOME/.local/bin/tg-send" "Bootstrap finished on $(hostname) after fresh install." 2>/dev/null || true
fi
