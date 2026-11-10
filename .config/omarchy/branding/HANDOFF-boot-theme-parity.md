# Handoff: Boot theme parity — sky → rain (limine / LUKS plymouth / SDDM login)

## Context
- Goal: reproduce on `rain` the boot-chain branding already done on `sky`: limine menu theme, plymouth LUKS-unlock + splash theme, SDDM login theme.
- Written on `rain` (192.168.1.109) 2026-11-10. `sky` = 192.168.1.107, ssh alias `sky` (key `id_rain`) — unreachable at time of writing (`No route to host`), so no direct diff was possible.
- Dotfiles: bare repo `~/.dotfiles`, work-tree `~`, branch `main`, HEAD `814bfdb` == `origin/main` (github.com:denialbb/.dotfiles). Omarchy tree clean; only 4 unrelated modified files (`opencode` plugins, `.gemini`, `.pi` settings).
- Sky boot work already committed and present on rain: `ae42553` (`post-update.d/reapply-boot-matrix.hook`), `f683714` + `24b22aa` (`branding/build-denial-theme.sh` matrix tint + PIL pin), `534fc7c` (logos).
- Verified on rain: plymouth theme `denial` installed at `/usr/share/plymouth/themes/denial` and default (`plymouth-set-default-theme` → `denial`); effective mkinitcpio HOOKS include `plymouth` + `encrypt`; install log and journal (Nov 8 23:33) show `limine-mkinitcpio` and `plymouth-set-default-theme denial` ran.
- NOT verified on rain: `/boot/limine.conf` branding (root-only, see Blockers).
- Missing on rain: any SDDM/login theming. `git grep sddm HEAD` matches only `reapply-lock-usb.hook` and `pkglist-native.txt`; `/usr/share/sddm/themes/omarchy` is pristine package content (Tokyo Night `#1a1b26`, omarchy logo).

## Decisions Made
- Transport: this handoff is committed to the dotfiles repo (identical relative path on both machines) and mirrored into the syncthing sendreceive folder `~/Documents/other` (device `sky`) so sky receives it without needing network git access.
- Single source of truth for theming = the dotfiles artifacts (`build-denial-theme.sh`, `reapply-boot-matrix.hook`). Any manual system edit on sky that produced the login theme must be committed, otherwise parity cannot be reproduced.
- Plymouth theme is *derived* from package base `/usr/share/plymouth/themes/omarchy` — always rebuild via the script, never hand-edit `/usr/share/plymouth/themes/denial`.
- UKIs are built with `limine-mkinitcpio`, not `mkinitcpio -P` (`/etc/mkinitcpio.d/` is empty → no presets).

## Unfinished Tasks
- Login/SDDM theme: absent on rain, and its sky-side source of truth is unknown.
- Limine Matrix branding on rain: state unknown; last guard run suggests it did not apply.
- `reapply-boot-matrix.hook` robustness: it only rewrites when `interface_branding:` already exists → silent no-op on a regenerated conf.
- Stray `/etc/plymouth/plymouthd.confe` (typo) on rain; the real `/etc/plymouth/plymouthd.conf` correctly has `Theme=denial`.
- Plymouth theme drift: `denial` was built Sep 17 from an older omarchy base; the package base changed Nov 5 (omarchy 4.5.0).

## Next Actions
1. On sky (agent cwd likely `~/.config`): `git pull` dotfiles, then read this file at `.config/omarchy/branding/HANDOFF-boot-theme-parity.md` (mirror: `~/Documents/other/handoffs/`).
2. On sky, inventory what was actually done for the "login theme": `pacman -Qkk sddm omarchy-settings | grep -i altered`; `ls -la /usr/share/sddm/themes/`; `git -C ~/.dotfiles --work-tree=~ status --short`; compare `/usr/share/sddm/themes/*` against `~/.config/omarchy/branding/`.
3. If sky's login theme is a manual edit of `/usr/share/sddm/themes/omarchy` (Main.qml background `#1a1b26` + matrix-tinted `lock/entry/bullet/logo` PNGs), extract it into `~/.config/omarchy/branding/build-denial-login-theme.sh` modelled on `build-denial-theme.sh`, commit it, and extend `reapply-boot-matrix.hook` to reapply it (including the case where the key/file is missing).
4. On rain: run the root check (Blockers) → if `interface_branding: denial` is absent, apply the hook's sed set and `sudo limine-mkinitcpio`.
5. Decide autologin: `/etc/sddm.conf.d/autologin.conf` (`User=denial`, `Session=omarchy.desktop`) skips the login screen entirely, so the login theme is invisible regardless. Disable on both machines if the theme is meant to be seen.
6. Rebuild `denial` from the current package base (`~/.config/omarchy/branding/build-denial-theme.sh` is idempotent), then `sudo limine-mkinitcpio`.
7. Commit + push from whichever machine; a rerun should then be a no-op.

## Suggested Skills
- `handoff` / `load-handoff` — resume or extend this thread.
- `omarchy` — required before touching omarchy/limine/plymouth/sddm or anything under `~/.config`.
- `diagnosing-bugs` — if a rebuilt theme does not render (verify `plymouth-set-default-theme`, initramfs contents, journal).
- `tg-send` — this spans two machines and reboots; notify on completion.

## Blockers / Notes
- rain `/boot` is `0700 root`; `sudo -n` fails (password required, `timestamp_timeout=10`). Agents cannot read `limine.conf` non-interactively. Hand the user this one-liner:
  `sudo sh -c 'grep -E "^(interface_branding|interface_branding_color|backdrop|term_background|term_foreground):" /boot/limine.conf; ls /boot; lsinitcpio /boot/initramfs-linux-omarchy*.img | grep -c plymouth'`
- Evidence limine branding did NOT apply on rain: journal 2026-11-10 00:42 replaced `/boot/limine.conf` via pkexec (backup `/boot/limine.conf.bak.20261110004147`), then 01:13 ran `test -f`, `grep -q ^interface_branding:`, `grep ^interface_branding:` with no subsequent `sed` → guard failed, no rewrite.
- Package baseline on rain: plymouth 26.134.222-3, limine 12.9.4-1, limine-mkinitcpio-hook 1.40.0-2, limine-snapper-sync 1.32.1-2, sddm 0.21.0-7, omarchy 4.5.0-3.
- Misleading file: `/etc/mkinitcpio.conf` shows `HOOKS=(base systemd …)`, but the effective line comes from `/etc/mkinitcpio.conf.d/00-omarchy-hooks.conf` (+ `omarchy_hooks.conf`, `omarchy_resume.conf`): `base udev plymouth keyboard autodetect microcode modconf kms keymap consolefont block encrypt filesystems fsck btrfs-overlayfs resume`. Do not "fix" `mkinitcpio.conf`.
- LUKS keyfile / USB auto-unlock is a separate topic, documented in `~/Documents/omarchy-luks-usb-setup.md`; rain has no `/etc/mkinitcpio.conf.d/vfat.conf`.
- Syncthing shares with device `sky`: only `~/Documents/other` (label KeePass) and `~/Pictures/wallpapers`, both sendreceive. Mirror of this doc goes to `~/Documents/other/handoffs/`.
- No secrets in this document.
