# Tailscale DNS failover (sky)

homebox (100.103.137.69) is both the tailnet DNS resolver and this box's exit
node. When homebox is down, this box loses DNS and internet. A user-level
watchdog fails over to local DNS + direct routing, then restores on recovery.

## Components

- `~/.local/bin/tailscale-dns-failover` — probe + failover script
- `~/.config/systemd/user/tailscale-dns-failover.service` — oneshot unit
- `~/.config/systemd/user/tailscale-dns-failover.timer` — every 30s
  (`OnBootSec=1min`, `OnUnitActiveSec=30s`)
- `~/.cache/tailscale-dns-failover/` — state (`fails`, `oks`, `failed`)

## Behavior

| Probe result | Action |
|---|---|
| ping + DNS ok (2× in a row, was failed over) | `tailscale set --accept-dns=true --exit-node=100.103.137.69` |
| ping dead (2× in a row) | `tailscale set --accept-dns=false --exit-node=` |
| ping ok, homebox DNS dead (2× in a row) | `tailscale set --accept-dns=false` (exit node kept) |
| anything, single failure | no-op (2-strike hysteresis vs. packet loss) |

Fallback DNS comes from wlan0 DHCP (8.8.8.8, 1.1.1.1). Desktop
notification is sent on every transition.

## Prereqs

Passwordless `tailscale set` (run once, needs sudo):

```bash
sudo tailscale set --operator="$USER"
```

Without it the script exits 1 and logs a hint to the journal.

## Operate

```bash
systemctl --user status tailscale-dns-failover.timer
journalctl --user -u tailscale-dns-failover.service --since "1 hour ago"
~/.local/bin/tailscale-dns-failover; echo "rc=$?"   # manual probe, no-op when healthy
```

## Why local, not tailnet-wide

Split-DNS in the admin console would change resolution for every device.
Only sky needs the failover, so it lives here. Revisit if other nodes
need it.
