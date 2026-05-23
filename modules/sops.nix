{ config, lib, pkgs, ... }:
{
  # sops-nix infrastructure ready; no secrets migrated yet.
  sops.age = {
    sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    generateKey = false;
  };
}
