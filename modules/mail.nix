{ config, pkgs, lib, ... }:
{
  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = "mail.cloudvkn.com";
    domains = [ "cloudvkn.com" ];

    loginAccounts = {
      "nali@cloudvkn.com" = {
        hashedPasswordFile = "/var/lib/mail-secrets/nali.pass";
        aliases = [
          "support@cloudvkn.com"
          "dmarc@cloudvkn.com"
          "postmaster@cloudvkn.com"
          "abuse@cloudvkn.com"
        ];
      };
    };

    certificateScheme = "manual";
    certificateFile = "/var/lib/acme/mail.cloudvkn.com/fullchain.pem";
    keyFile = "/var/lib/acme/mail.cloudvkn.com/key.pem";

    dkimSelector = "mail";
    dkimKeyBits = 2048;

    enableManageSieve = true;
    localDnsResolver = true;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "nali@cloudvkn.com";

    certs."mail.cloudvkn.com" = {
      dnsProvider = "cloudflare";
      environmentFile = "/var/lib/secrets/cloudflare-dns.env";
      dnsResolver = "1.1.1.1:53";
      reloadServices = [ "postfix.service" "dovecot.service" ];
    };
  };
}
