{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    harmonia
  ];

  services.harmonia = {
    enable = true;

    signKeyPaths = [
      "/var/lib/secrets/harmonia/cache.secret"
    ];

    settings = {
      bind = "127.0.0.1:5000";
      workers = 4;
      max_connection_rate = 256;
      priority = 30;
    };
  };
}
