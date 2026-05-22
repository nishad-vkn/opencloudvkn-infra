{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.cache.enable {
  services.harmonia = {
    enable = true;
    signKeyPaths = [ "/var/lib/secrets/harmonia/cache.secret" ];
    settings = {
      bind = "127.0.0.1:5000";
      workers = 4;
      max_connection_rate = 256;
      priority = 30;
    };
  };

  # Make THIS server also consume its own cache + upstream, and trust its key.
  nix.settings = {
    substituters = lib.mkBefore [ "https://cache.${cfg.domain}" ];
    trusted-public-keys = [
      # Replace with: cat /var/lib/secrets/harmonia/cache.pk  (your public key)
      "cache.${cfg.domain}-1:3h7ExdxdAmb9DK6rvVLkFc0TIcrAVZjMhLdHPVAr0Bg="
    ];
  };
}
