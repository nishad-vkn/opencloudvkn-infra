# opencloudvkn-infra

Public NixOS configuration for the OpenCloudVKN public VPS.

- Host: `vps-01`
- IP:   `209.182.234.229`
- DNS:  `opencloudvkn.com`

## Install command

Run on a fresh Debian 12 VPS:

```bash
curl --proto "=https" --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install linux --no-confirm --init none
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

nix --extra-experimental-features "nix-command flakes" run github:nix-community/nixos-anywhere -- \
    --flake github:nishad-vkn/opencloudvkn-infra#vps-01 \
    --target-host root@localhost
```

After install, future rebuilds:

```bash
ssh nali@209.182.234.229
sudo nixos-rebuild switch --flake github:nishad-vkn/opencloudvkn-infra#vps-01
```
