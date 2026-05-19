{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    package = pkgs.caddy;

    globalConfig = ''
      email admin@opencloudvkn.com
    '';

    virtualHosts = {
      "opencloudvkn.com".extraConfig = ''
        redir https://www.opencloudvkn.com{uri} permanent
      '';

      "www.opencloudvkn.com".extraConfig = ''
        header {
          Strict-Transport-Security "max-age=31536000"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          Referrer-Policy "strict-origin-when-cross-origin"
          -Server
        }

        respond "OpenCloudVKN base NixOS server is live." 200
      '';
    };
  };

  systemd.services.caddy.serviceConfig = {
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectHome = true;
  };
}
