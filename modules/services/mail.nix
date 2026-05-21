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

  # ── IPv6 workaround ──────────────────────────────────────────────
  # This VPS has broken outbound IPv6 (SSDNodes upstream). Postfix otherwise
  # prefers IPv6 for delivery, hangs ~30s on the dead v6 path, then falls back
  # to v4 — causing slow/failed sends to v6-capable MX (most corporate mail).
  # Force IPv4 for all SMTP delivery until provider IPv6 is fixed.
  services.postfix.settings.main = {
    inet_protocols = "ipv4";
    smtp_address_preference = "ipv4";
  };
}
