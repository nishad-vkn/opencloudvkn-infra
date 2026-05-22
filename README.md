# CloudVKN Infrastructure

Self-hosted cloud platform on NixOS, serving mail, git, a Nix binary cache, and
monitoring under `cloudvkn.com`. Built with a SelfPrivacy-inspired structure:
a central option tree, per-service modules, wildcard ACME certs, and
systemd-sandboxed services with resource slices.

## Overview

| Service | Address | Notes |
|---|---|---|
| Mail | `mail.cloudvkn.com` | nixos-mailserver (Postfix/Dovecot/rspamd), real LE wildcard cert |
| Git | `git.cloudvkn.com` | Forgejo, login-gated, 2FA admin, SSH on :2222 |
| Cache | `cache.cloudvkn.com` | Harmonia Nix binary cache |
| Monitoring | `10.88.0.1:3001` / `:9090` | Uptime Kuma + Prometheus (WireGuard-only) |
| VPN | `wg0` 10.88.0.0/24 | WireGuard, 7 peers |

- **Host**: SSDNodes Tokyo VPS, NixOS 25.11, 2 vCPU / 8 GB / 160 GB
- **DNS**: Cloudflare (DNS-only / gray cloud)
- **Admin user**: `nali` (wheel, key-only SSH, passwordless sudo)

## Repository layout
cloudvkn.nix                 # central option tree (domain, admin, service toggles)
flake.nix                    # system definition; imports all modules
lib/acme.nix                 # wildcard *.cloudvkn.com DNS-01 cert + acmereceivers group
hosts/vps-01/                # host-specific: disko, hardware, networking
modules/
base.nix  hardening.nix  users.nix  ssh.nix  firewall.nix
webserver.nix              # Caddy, wildcard cert, all vhosts
wireguard.nix              # VPN (frozen — do not modify)
postgresql.nix
lib/mail-submission.nix    # local trusted SMTP submission for services
services/
git/      { default, core, hardening }    # Forgejo
cache/    { default, core, hardening }    # Harmonia
monitoring.nix                            # Uptime Kuma
prometheus.nix                            # Prometheus + node_exporter
web-fail2ban.nix                          # Forgejo brute-force jail
mail/     { default, core, permissions, antispam, hardening,
fail2ban, antivirus, backup, reporting, watchdog, healthcheck }
## Central configuration

All services read from `config.cloudvkn.*` (defined in `cloudvkn.nix`) — no
hardcoded domain literals. Services are toggled in `flake.nix`:

```nix
cloudvkn.services.forgejo.enable = true;
cloudvkn.services.cache.enable = true;
cloudvkn.services.monitoring.enable = true;
cloudvkn.services.mail = {
  enable = true;
  fail2ban.enable = true;
  antivirus.enable = true;     # ClamAV, capped via system-clamav.slice
  backup.enable = false;       # borgbackup (needs passphrase)
  reporting.enable = false;    # SRS + DMARC + TLS-RPT (needs DNS records)
};
```

## TLS / certificates

A single wildcard cert for `*.cloudvkn.com` is issued via Let's Encrypt
DNS-01 (Cloudflare API). The cert name is the bare domain (`cloudvkn.com`),
deliberately different from the mail FQDN (`mail.cloudvkn.com`) so the
mailserver consumes it via `certificateScheme = "manual"` instead of
generating a self-signed minica cert.

Note: this VPS has broken outbound IPv6, so lego's DNS propagation self-check
is disabled (`dnsPropagationCheck = false`) and Postfix is forced to IPv4
(`inet_protocols = ipv4`). Let's Encrypt validates server-side regardless.

The Cloudflare token lives in `/var/lib/secrets/cloudflare-dns.env`
(mode 0440, group `acme`).

## Security model

- **Per-service users**: each service runs as its own non-login system user.
- **acmereceivers group**: cert read access delegated to caddy, postfix,
  dovecot2, virtualMail via group membership (no world-readable keys).
- **systemd sandboxing**: services use ProtectSystem=strict, NoNewPrivileges,
  RestrictAddressFamilies, SystemCallFilter, etc. (pattern from upstream
  nixos-mailserver's rspamd module).
- **Resource slices**: mailstack, git, cache, monitoring, system-clamav slices
  cap MemoryMax / CPUQuota per service group.
- **fail2ban**: jails for dovecot, postfix-sasl, sshd, forgejo.
- **Admin**: `nali` with 2FA on Forgejo; SSH key-only.

## Mail

- Accounts: `nali@cloudvkn.com` (personal + Forgejo login),
  `support@cloudvkn.com` (ops/system sender + monitoring login).
- Aliases: postmaster@/abuse@ -> nali; dmarc@ -> support.
- DKIM: selector `mail`, 2048-bit RSA, published in Cloudflare.
- DNS: SPF hardfail, DMARC quarantine (strict), MTA-STS (testing), TLS-RPT.
- Services send mail via local trusted submission (Postfix mynetworks
  127.0.0.0/8) as `support@cloudvkn.com`.

### Client settings

- IMAP: `mail.cloudvkn.com:993` SSL/TLS
- SMTP: `mail.cloudvkn.com:465` SSL/TLS
- Username: full address (e.g. `nali@cloudvkn.com`)

## Monitoring

- **Uptime Kuma** (`10.88.0.1:3001`, WireGuard-only): port/cert/HTTP checks.
- **Prometheus** (`10.88.0.1:9090`, WireGuard-only) + node_exporter
  (`127.0.0.1:9100`): system + rspamd metrics, 30-day retention.
- **mail-healthcheck** timer (15 min): queue depth, blacklist, disk, cert
  expiry, service liveness -> emails support@ on problems.
- **OnFailure alerts**: postfix/dovecot/rspamd failures email an alert.

## Deploying changes

```bash
cd /etc/nixos
git add -A
sudo nixos-rebuild test --flake /etc/nixos#vps-01     # activate, reboot recovers
# verify, then:
sudo nixos-rebuild switch --flake /etc/nixos#vps-01   # make permanent
git commit -am "..." && git push
```

Build from a clean checkout:

```bash
sudo nixos-rebuild switch --flake github:nishad-vkn/opencloudvkn-infra#vps-01
```

Always `git add -A` before rebuild — flakes only see git-tracked files.

## WireGuard

`wg0` on 10.88.0.0/24, server 10.88.0.1, UDP 51820, 7 peers. This module is
frozen — do not modify. WireGuard-only services (Uptime Kuma, Prometheus)
bind to 10.88.0.1 and are unreachable from the public internet.
