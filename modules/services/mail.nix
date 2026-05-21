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

    loginAccounts."${cfg.adminUser}@${cfg.domain}" = {
      hashedPasswordFile = "/var/lib/mail-secrets/nali.pass";
      aliases = [
        "support@${cfg.domain}"
        "dmarc@${cfg.domain}"
        "postmaster@${cfg.domain}"
        "abuse@${cfg.domain}"
      ];
    };

    # Reuse the wildcard ACME cert (name = domain, != mail fqdn => no minica hijack).
    certificateScheme = "manual";
    certificateFile = "${certDir}/fullchain.pem";
    keyFile = "${certDir}/key.pem";

    dkimSelector = "mail";
    dkimKeyBits = 2048;
    enableManageSieve = true;
    localDnsResolver = true;
  };
}
