{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
  certDir = config.security.acme.certs.${cfg.domain}.directory;
in
lib.mkIf cfg.services.mail.enable {
  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = "mail.${cfg.domain}";
    domains = [ cfg.domain ];

    loginAccounts = {
      # Primary admin mailbox (Forgejo login, personal).
      "${cfg.adminUser}@${cfg.domain}" = {
        hashedPasswordFile = "/var/lib/mail-secrets/nali.pass";
        aliases = [
          "postmaster@${cfg.domain}"
          "abuse@${cfg.domain}"
        ];
      };

      # Real ops mailbox: system/notification sender + monitoring login.
      "support@${cfg.domain}" = {
        hashedPasswordFile = "/var/lib/mail-secrets/support.pass";
        aliases = [
          "dmarc@${cfg.domain}"
        ];
      };
    };

    certificateScheme = "manual";
    certificateFile = "${certDir}/fullchain.pem";
    keyFile = "${certDir}/key.pem";

    dkimSelector = "mail";
    dkimKeyBits = 2048;
    enableManageSieve = true;
    localDnsResolver = true;
  };

  services.postfix.settings.main = {
    inet_protocols = "ipv4";
    smtp_address_preference = "ipv4";
  };
}
