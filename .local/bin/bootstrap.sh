#!/usr/bin/env bash
# ==============================================================================
# Omarchy Post-Install & Dotfiles Bootstrap Script (Animated & Styled)
# ==============================================================================
set -euo pipefail

# Colors & Formatting
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_DIM="\033[2m"
CLR_CYAN="\033[38;2;122;162;247m"
CLR_BLUE="\033[38;2;125;207;255m"
CLR_PURPLE="\033[38;2;187;154;247m"
CLR_GREEN="\033[38;2;158;206;106m"
CLR_YELLOW="\033[38;2;224;175;104m"
CLR_RED="\033[38;2;247;118;142m"
CLR_MUTED="\033[38;2;86;95;137m"

DOTFILES_REPO="git@github.com:denialbb/.dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
NVIM_REPO="git@github.com:denialbb/nvim.git"
NVIM_DIR="$HOME/.config/nvim"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%s)"

# Never prompt for SSH passphrases/host keys inside this script: interactive
# prompts are invisible under `gum spin` and look like a hang. Fail fast
# instead — ensure_github_ssh() below gives the fix-it steps up front.
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=30 -o StrictHostKeyChecking=accept-new"

# Animation & Status Helpers
HAS_GUM=0
if command -v gum &>/dev/null; then
    HAS_GUM=1
fi

print_header() {
    clear 2>/dev/null || true
    echo -e "${CLR_PURPLE}${CLR_BOLD}"
    cat << "BANNER"
  ___  __  __   _   ___  ___ _  ___   __
 / _ \|  \/  | /_\ | _ \/ __| || \ \ / /
| (_) | |\/| |/ _ \|   / (__| __ |\ V / 
 \___/|_|  |_/_/ \_\_|_\\___|_||_| |_|  
BANNER
    echo -e "${CLR_CYAN}  ▶ Omarchy Post-Install & Dotfiles Bootstrap ◀${CLR_RESET}"
    echo -e "${CLR_MUTED}  ────────────────────────────────────────────${CLR_RESET}\n"
}

step_header() {
    local num="$1"
    local total="$2"
    local msg="$3"
    echo -e "\n${CLR_CYAN}${CLR_BOLD}[${num}/${total}]${CLR_RESET} ${CLR_BOLD}${msg}${CLR_RESET}"
}

# NOTE: never wrap commands that can prompt (ssh/passphrase, sudo, yay -S)
# or do network I/O in run_with_spinner — their prompts/progress are hidden
# and a stall looks like a hang. Run those visibly instead.
run_with_spinner() {
    local title="$1"
    shift
    if [ "$HAS_GUM" -eq 1 ]; then
        gum spin --spinner dot --spinner.foreground="212" --title "$title" -- "$@"
    else
        echo -ne "  ${CLR_BLUE}⠋${CLR_RESET} ${title}..."
        "$@" >/dev/null 2>&1 &
        local pid=$!
        local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local i=0
        while kill -0 "$pid" 2>/dev/null; do
            i=$(( (i+1) % 10 ))
            echo -ne "\r  ${CLR_CYAN}${spin:$i:1}${CLR_RESET} ${title}..."
            sleep 0.08
        done
        wait "$pid"
        echo -ne "\r\033[K"
    fi
}

log_ok() {
    echo -e "  ${CLR_GREEN}✔${CLR_RESET} $1"
}

log_warn() {
    echo -e "  ${CLR_YELLOW}⚠${CLR_RESET} $1"
}

log_info() {
    echo -e "  ${CLR_MUTED}➜${CLR_RESET} $1"
}

# ------------------------------------------------------------------------------
# Main Bootstrap Workflow
# ------------------------------------------------------------------------------

print_header

config() {
    /usr/bin/git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

# Pre-flight: GitHub SSH must work before any clone attempt. With
# BatchMode all later git-over-SSH ops fail fast instead of hanging on a
# hidden passphrase prompt, so check once here with a helpful message.
ensure_github_ssh() {
    local out
    out=$(ssh -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)
    if grep -qi "successfully authenticated" <<< "$out"; then
        log_ok "GitHub SSH authentication OK."
        return 0
    fi
    echo -e "  ${CLR_RED}✘${CLR_RESET} GitHub SSH authentication failed:"
    echo "$out" | sed 's/^/    /'
    echo -e "  ${CLR_YELLOW}Fix and re-run:${CLR_RESET}"
    echo '    1. eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519   # visible passphrase prompt'
    echo '    2. ssh -T git@github.com   # expect: Hi <user>! You have successfully authenticated'
    echo '    3. Still rejected? Upload ~/.ssh/id_ed25519.pub at github.com/settings/keys,'
    echo '       or copy .ssh/ off the USB backup first (README fresh-install step 2).'
    exit 1
}

# Step 1
step_header "1" "7" "Initializing Dotfiles Bare Repository"
ensure_github_ssh
if [ ! -d "$DOTFILES_DIR" ]; then
    log_info "Cloning bare repository from GitHub (visible progress, not hidden in spinner)..."
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
    log_ok "Dotfiles repository cloned."
else
    log_ok "Bare repository already present at ${CLR_DIM}${DOTFILES_DIR}${CLR_RESET}."
fi
config config --local status.showUntrackedFiles no
log_ok "Untracked file noise suppressed (status.showUntrackedFiles = no)."

# Step 2
step_header "2" "7" "Checking Out Working Tree & Resolving Conflicts"
if config checkout >/dev/null 2>&1; then
    log_ok "Dotfiles checked out directly without conflicts."
else
    log_warn "Conflicting pre-existing configs detected. Moving to backup..."
    mkdir -p "$BACKUP_DIR"
    # Checkout error lists each blocker on its own indented line, e.g.:
    #   <tab>.config/mise/config.toml
    # Take the whole line (filenames may contain spaces, e.g. bat themes),
    # so strip leading whitespace instead of awk '{print $1}'.
    config checkout 2>&1 | awk '/^[[:space:]]/ { sub(/^[[:space:]]+/, ""); if (length) print }' | while IFS= read -r file; do
        if [ -e "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$file")"
            mv "$HOME/$file" "$BACKUP_DIR/$file"
        fi
    done
    config checkout
    log_ok "Backup created at ${CLR_YELLOW}${BACKUP_DIR}${CLR_RESET} and checkout finished."
fi

# Ensure ~/.local/bin is executable
if [ -d "$HOME/.local/bin" ]; then
    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
    log_ok "Executable permissions granted to ~/.local/bin scripts."
fi

# Step 3
step_header "3" "7" "Installing Curated Native Arch Packages"
if [ -f "$HOME/.config/pkglist-native.txt" ]; then
    log_info "Synchronizing official repositories..."
    sudo pacman -S --needed --noconfirm - < "$HOME/.config/pkglist-native.txt"
    log_ok "Native packages installed successfully."
else
    log_warn "pkglist-native.txt not found, skipping pacman batch install."
fi

# Step 4
step_header "4" "7" "Installing AUR Packages via Yay"
if ! command -v yay &>/dev/null; then
    log_info "Building yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    TEMP_YAY=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TEMP_YAY/yay"
    (cd "$TEMP_YAY/yay" && makepkg -si --noconfirm)
    rm -rf "$TEMP_YAY"
    log_ok "Yay installed."
fi

if [ -f "$HOME/.config/pkglist-aur.txt" ]; then
    log_info "Installing AUR packages..."
    yay -S --needed --noconfirm - < "$HOME/.config/pkglist-aur.txt"
    log_ok "AUR packages installed successfully."
else
    log_warn "pkglist-aur.txt not found, skipping AUR batch install."
fi

# Step 5
step_header "5" "7" "Setting Up Neovim Configuration"
if [ ! -d "$NVIM_DIR" ]; then
    log_info "Cloning Neovim configuration (visible progress, not hidden in spinner)..."
    git clone "$NVIM_REPO" "$NVIM_DIR"
    log_ok "Neovim config cloned."
elif [ ! -d "$NVIM_DIR/.git" ]; then
    log_warn "Existing ~/.config/nvim is not a git repository. Archiving..."
    mv "$NVIM_DIR" "${NVIM_DIR}.bak.$(date +%s)"
    log_info "Cloning Neovim configuration (visible progress, not hidden in spinner)..."
    git clone "$NVIM_REPO" "$NVIM_DIR"
    log_ok "Fresh Neovim config cloned."
else
    log_info "Updating existing Neovim config..."
    if git -C "$NVIM_DIR" pull --ff-only; then
        log_ok "Neovim configuration up to date."
    else
        log_warn "Neovim update failed (network/SSH?) — keeping existing checkout."
    fi
fi

# Step 6
step_header "6" "7" "Restoring Language Runtimes (Mise)"
if command -v mise &>/dev/null && [ -f "$HOME/.config/mise/config.toml" ]; then
    log_info "Installing runtimes declared in ~/.config/mise/config.toml..."
    mise install -y || true
    log_ok "Mise runtimes restored."
    if command -v uv &>/dev/null; then
        uv tool install kaggle >/dev/null 2>&1 || true
        log_ok "CLI tools restored via uv (kaggle)."
    fi
    if command -v fish &>/dev/null && [ -f "$HOME/.config/fish/fish_plugins" ]; then
        if ! fish -c "type -q fisher" 2>/dev/null; then
            fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" >/dev/null 2>&1 || true
        fi
        fish -c "fisher update" >/dev/null 2>&1 || true
        log_ok "Fish plugins synchronized via Fisher."
    fi
else
    log_info "Mise not configured or config missing, skipping."
fi

# Step 7
step_header "7" "7" "Activating Systemd User Units"
systemctl --user daemon-reload || true
USER_SERVICES=(
    "articles-server.service"
    "voxtype.service"
    "ydotoold.service"
    "swayosd-server.service"
    "elephant.service"
    "omarchy-recover-internal-monitor.service"
    "omarchy-lid-inhibit.service"
)

for svc in "${USER_SERVICES[@]}"; do
    if [ -f "$HOME/.config/systemd/user/$svc" ]; then
        if systemctl --user enable --now "$svc" >/dev/null 2>&1; then
            log_ok "Activated ${CLR_GREEN}$svc${CLR_RESET}"
        else
            log_warn "Could not start $svc (may need manual configuration)."
        fi
    fi
done

# ------------------------------------------------------------------------------
# Completion Box
# ------------------------------------------------------------------------------
echo ""
if [ "$HAS_GUM" -eq 1 ]; then
    gum style \
        --border double \
        --border-foreground 212 \
        --padding "1 2" \
        --margin "1 0" \
        "$(echo -e "${CLR_GREEN}${CLR_BOLD}★ Omarchy Bootstrap Complete! ★${CLR_RESET}\n\n${CLR_CYAN}Next Steps:${CLR_RESET}\n1. Run: ${CLR_PURPLE}omarchy theme set <theme-name>${CLR_RESET}\n2. Restart or log out to finalize user session.")"
else
    echo -e "${CLR_GREEN}${CLR_BOLD}========================================================================${CLR_RESET}"
    echo -e "${CLR_GREEN}${CLR_BOLD}  ★ Omarchy Bootstrap Complete! ★${CLR_RESET}"
    echo -e "${CLR_CYAN}  Next Steps:${CLR_RESET}"
    echo -e "    1. Run: ${CLR_PURPLE}omarchy theme set <theme-name>${CLR_RESET}"
    echo -e "    2. Restart or log out to finalize user session."
    echo -e "${CLR_GREEN}${CLR_BOLD}========================================================================${CLR_RESET}"
fi

# Telegram notification
if command -v "$HOME/.local/bin/tg-send" &>/dev/null && [ -f "$HOME/.config/telegram-notify.conf" ]; then
    "$HOME/.local/bin/tg-send" "Omarchy Bootstrap finished on $(hostname)!" 2>/dev/null || true
fi
