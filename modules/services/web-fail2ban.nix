{ config, lib, ... }:
let
  cfg = config.cloudvkn;
  f2bOn = cfg.services.mail.fail2ban.enable;
in
lib.mkIf (f2bOn && cfg.services.forgejo.enable) {
  environment.etc."fail2ban/filter.d/forgejo.conf".text = ''
    [Definition]
    failregex = .*(Failed authentication attempt|invalid credentials|Attempted access of unknown user|user does not exist).* from <HOST>
    journalmatch = _SYSTEMD_UNIT=forgejo.service
    ignoreregex =
  '';

  services.fail2ban.jails.forgejo.settings = {
    filter = "forgejo";
    backend = "systemd";
    maxretry = 5;
    findtime = "10m";
    bantime = "1h";
    port = "http,https,2222";
  };
}
