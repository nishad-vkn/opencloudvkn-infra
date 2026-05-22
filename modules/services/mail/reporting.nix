{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf (cfg.services.mail.enable && cfg.services.mail.reporting.enable) {
  mailserver = {
    systemContact = "postmaster@${cfg.domain}";
    systemName = "CloudVKN mail system";

    # Forward mail without breaking SPF.
    srs.enable = true;

    # Send aggregated DMARC reports + TLS reports (RFC 8460).
    dmarcReporting.enable = true;
    tlsrpt.enable = true;
  };
}
