{ config, pkgs, lib, ... }:
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy;

    globalConfig = ''
      email admin@cloudvkn.com
    '';

    virtualHosts = {
      "cloudvkn.com".extraConfig = ''
        redir https://www.cloudvkn.com{uri} permanent
      '';

      "www.cloudvkn.com".extraConfig = ''
        header {
          Strict-Transport-Security "max-age=31536000"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          Referrer-Policy "strict-origin-when-cross-origin"
          -Server
        }
        respond "CloudVKN base NixOS server is live and healthy." 200
      '';

      "git.cloudvkn.com".extraConfig = ''
        encode zstd gzip
        header {
          Strict-Transport-Security "max-age=31536000"
          X-Content-Type-Options "nosniff"
          Referrer-Policy "strict-origin-when-cross-origin"
          -Server
        }
        reverse_proxy 127.0.0.1:3000
      '';

      "cache.cloudvkn.com".extraConfig = ''
        header {
          Strict-Transport-Security "max-age=31536000"
          X-Content-Type-Options "nosniff"
          -Server
        }
        reverse_proxy 127.0.0.1:5000
      '';
    };
  };

  systemd.services.caddy.serviceConfig = {
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectHome = true;
  };
}
