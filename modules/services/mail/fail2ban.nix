{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf (cfg.services.mail.enable && cfg.services.mail.fail2ban.enable) {
  services.fail2ban = {
    enable = true;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "168h";
      factor = "2";
    };
    ignoreIP = [
      "127.0.0.1/8"
      "::1"
      "10.88.0.0/24"   # WireGuard peers never banned
    ];
    jails = {
      postfix-sasl.settings = {
        filter = "postfix[mode=auth]";
        backend = "systemd";
        maxretry = 5;
        port = "smtp,submission,submissions";
      };
      dovecot.settings = {
        filter = "dovecot";
        backend = "systemd";
        maxretry = 5;
        port = "imap,imaps,pop3,pop3s,submission,submissions,sieve";
      };
    };
  };
}
