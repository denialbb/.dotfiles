# Tailscale setup on a new PC (Arch / Omarchy)

Tailnet: `tailef5773.ts.net`. DNS resolver + exit node: homebox
(100.103.137.69). MagicDNS names: `<host>.tailef5773.ts.net`.

## Install + join

```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
sudo tailscale set --operator="$USER"   # passwordless `tailscale set` from now on
```

## Match sky's config

```bash
tailscale set --accept-dns=true --exit-node=100.103.137.69 --exit-node-allow-lan-access=true
tailscale status            # homebox should show active + exit node, selected
tailscale exit-node list    # confirm homebox is selected
nslookup homebox            # -> 100.103.137.69 via MagicDNS
```

## DNS failover (recommended)

Copies of sky's watchdog — required on any box using homebox as resolver:

- `~/.local/bin/tailscale-dns-failover`
- `~/.config/systemd/user/tailscale-dns-failover.{service,timer}`
- doc: `~/.config/tailscale-dns-failover.md`

```bash
chmod +x ~/.local/bin/tailscale-dns-failover
systemctl --user daemon-reload
systemctl --user enable --now tailscale-dns-failover.timer
```

## Leave

```bash
tailscale logout   # or: sudo tailscale up --force-reauth to switch account
```
