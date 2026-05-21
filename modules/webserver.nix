{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
  d = cfg.domain;
  # Path where NixOS ACME stores the wildcard cert.
  certDir = config.security.acme.certs.${d}.directory;
  tlsLine = ''
    tls ${certDir}/cert.pem ${certDir}/key.pem
  '';
  secHeaders = ''
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains"
      X-Content-Type-Options "nosniff"
      X-Frame-Options "DENY"
      Referrer-Policy "strict-origin-when-cross-origin"
      -Server
    }
  '';
in
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy;
    globalConfig = ''
      email ${cfg.adminUser}@${d}
    '';

    virtualHosts = lib.mkMerge [
      {
        "${d}".extraConfig = ''
          ${tlsLine}
          redir https://www.${d}{uri} permanent
        '';
        "www.${d}".extraConfig = ''
          ${tlsLine}
          ${secHeaders}
          respond "CloudVKN is live and healthy." 200
        '';
        # MTA-STS policy (only meaningful when mail is on, but harmless otherwise).
        "mta-sts.${d}".extraConfig = ''
          ${tlsLine}
          header Content-Type "text/plain"
          respond /.well-known/mta-sts.txt "version: STSv1
mode: testing
mx: mail.${d}
max_age: 604800
" 200
          respond 404
        '';
      }

      (lib.mkIf cfg.services.forgejo.enable {
        "git.${d}".extraConfig = ''
          ${tlsLine}
          encode zstd gzip
          ${secHeaders}
          reverse_proxy 127.0.0.1:3000
        '';
      })

      (lib.mkIf cfg.services.cache.enable {
        "cache.${d}".extraConfig = ''
          ${tlsLine}
          ${secHeaders}
          reverse_proxy 127.0.0.1:5000
        '';
      })
    ];
  };

  systemd.services.caddy.serviceConfig = {
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectHome = true;
  };
}
