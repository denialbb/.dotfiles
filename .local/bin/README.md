# .dotfiles — Omarchy config (machine `sky`)

Bare repo: `git@github.com:denialbb/.dotfiles.git`. Manage with `/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME`.

## Fresh-install restore
1. Install Omarchy, create user `denial`, plug in USB backup (`~/Mount/USB/backup-omarchy`).
2. Get SSH to GitHub working first (`ssh -T git@github.com`; else `ssh-keygen -t ed25519` + upload, or copy `.ssh/` off USB).
3. Run: `~/.local/bin/restore.sh [backup-dir]` (default: script dir if it holds `pkglist-native.txt`, else `~/Mount/USB/backup-omarchy`).

What `restore.sh` does:
1. `hostnamectl set-hostname sky` + `/etc/hosts`
2. Copies `.secrets` (600), `.ssh/`, `.gnupg/`, `.claude.json`, notify confs, `openvpn/` from backup
3. Clones this repo (if needed) + runs `bootstrap.sh`: yay build, native+AUR pkgs from `~/.config/pkglist-*`, mise runtimes, fisher, nvim, systemd user units
4. Re-installs pkgs directly from backup `pkglist-*`
5. Restores app configs: opencode, pi settings/extensions, herdr, nom (+`nom.db`), antigravity, qutebrowser/Chromium bookmarks
6. `git clone`s projects: agent-skills, ai-tooling, kobo-notes, pi-extensions, limen, r-edit, AEGIS, aoc2019

Do NOT run `bootstrap.sh` standalone before checkout — it reads `~/.config/pkglist-*`, present only after checkout.

## After reboot
```bash
omarchy theme set firesky
pi login; opencode auth login   # auth.json never backed up
~/Projects/agent-skills/link-skills.sh  # re-link ~/.agents ~/.claude ~/.codex ~/.pi skills
```

## Manual gaps
- Chromium `Login Data` is GNOME-keyring encrypted; export CSV from old machine as fallback.
- `~/.pi/agent/auth.json` excluded deliberately. 1Password session not backed up.

## Verify
```bash
hostnamectl --static
git --git-dir=~/.dotfiles --work-tree=~ status   # → clean
pacman -Qqen | wc -l; pacman -Qqem | wc -l
```
