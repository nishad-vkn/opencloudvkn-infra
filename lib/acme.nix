{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
{
  users.groups.acmereceivers = { };

  systemd.tmpfiles.rules = [
    "z /var/lib/secrets/cloudflare-dns.env 0440 root acme - -"
  ];

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "${cfg.adminUser}@${cfg.domain}";
      dnsResolver = "1.1.1.1:53";
    };

    certs."${cfg.domain}" = {
      domain = cfg.domain;
      extraDomainNames = [ "*.${cfg.domain}" ];
      dnsProvider = "cloudflare";
      environmentFile = cfg.acmeEnvFile;
      group = "acmereceivers";
      dnsPropagationCheck = false;
      reloadServices = [ "caddy.service" ]
        ++ lib.optionals cfg.services.mail.enable [ "postfix.service" "dovecot.service" ];
    };
  };
}
