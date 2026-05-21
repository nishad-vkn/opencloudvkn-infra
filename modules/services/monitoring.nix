{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.monitoring.enable {
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "10.88.0.1";   # WireGuard interface only
      PORT = "3001";
    };
  };
}
