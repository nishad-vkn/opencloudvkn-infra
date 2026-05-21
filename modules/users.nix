{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
{
  users.mutableUsers = false;

  users.users.${cfg.adminUser} = {
    isNormalUser = true;
    description = "CloudVKN Admin";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = cfg.adminSSHKeys;
  };

  security.sudo = {
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  # Caddy reads the wildcard cert -> must be in acmereceivers.
  users.groups.acmereceivers.members =
    [ "caddy" ]
    ++ lib.optionals cfg.services.mail.enable [ "postfix" "dovecot2" "virtualMail" ];
}
