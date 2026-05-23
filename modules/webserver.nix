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

          @root path /
          handle @root {
            header Content-Type "text/html; charset=utf-8"
            respond `<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>cVkn Nix Cache</title>
<style>body{background:#0d1117;color:#c9d1d9;font-family:ui-monospace,Menlo,monospace;max-width:760px;margin:60px auto;padding:0 20px;line-height:1.6}h1{color:#58a6ff}pre{background:#161b22;border:1px solid #30363d;border-radius:6px;padding:16px;overflow:auto;font-size:.85rem}.key{color:#7ee787;word-break:break-all}a{color:#58a6ff}</style></head>
<body><h1>cVkn Nix Binary Cache</h1>
<p>Public Nix binary cache for cloudvkn projects.</p>
<h3>Add to your Nix config</h3>
<pre>nix.settings = {
  substituters = [ "https://cache.cloudvkn.com" "https://cache.nixos.org" ];
  trusted-public-keys = [
    "cache.cloudvkn.com-1:3h7ExdxdAmb9DK6rvVLkFc0TIcrAVZjMhLdHPVAr0Bg="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
};</pre>
<h3>Cache info</h3>
<p><a href="/nix-cache-info">/nix-cache-info</a> &middot; Priority 30 &middot; Harmonia</p>
<p style="color:#8b949e;font-size:.8rem">Public key:<br><span class="key">cache.cloudvkn.com-1:3h7ExdxdAmb9DK6rvVLkFc0TIcrAVZjMhLdHPVAr0Bg=</span></p>
</body></html>` 200
          }

          handle {
            reverse_proxy 127.0.0.1:5000
          }
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
