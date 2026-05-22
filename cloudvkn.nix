{ config, lib, ... }:
with lib;
{
  options.cloudvkn = {
    domain = mkOption {
      type = types.str;
      default = "cloudvkn.com";
      description = "Primary domain for all services.";
    };

    adminUser = mkOption {
      type = types.str;
      default = "nali";
      description = "Primary admin (login + sudo + mail).";
    };

    adminSSHKeys = mkOption {
      type = types.listOf types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElysVA40MN0V7vo4rG2NngRZGHtJB3+I5Uqg0+XJlnW t14@DESKTOP-BGEPD1V"
      ];
      description = "Authorized SSH public keys for the admin user.";
    };

    acmeEnvFile = mkOption {
      type = types.str;
      default = "/var/lib/secrets/cloudflare-dns.env";
      description = "EnvironmentFile holding the Cloudflare DNS API token.";
    };

    services = {
      forgejo.enable    = mkEnableOption "Forgejo git (git.<domain>)";
      cache.enable      = mkEnableOption "Harmonia binary cache (cache.<domain>)";
      monitoring.enable = mkEnableOption "Uptime Kuma (wg-only)";

      mail = {
        enable          = mkEnableOption "Mail server (mail.<domain>)";
        fail2ban.enable = mkEnableOption "Mail brute-force protection (fail2ban)";
        antivirus.enable= mkEnableOption "ClamAV virus scanning (resource-capped)";
        backup.enable   = mkEnableOption "Mail backups (borgbackup)";
        reporting.enable= mkEnableOption "SRS + DMARC reporting + TLS-RPT";
      };
    };
  };

  config = {
    networking.domain = config.cloudvkn.domain;
  };
}
