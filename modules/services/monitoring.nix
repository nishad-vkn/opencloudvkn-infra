{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.monitoring.enable {
  services.uptime-kuma = {
    enable = true;
    settings = { HOST = "10.88.0.1"; PORT = "3001"; };
  };

  systemd.slices.monitoring = {
    description = "CloudVKN monitoring slice";
    sliceConfig = { MemoryHigh = "768M"; MemoryMax = "1G"; CPUQuota = "100%"; };
  };

  systemd.services.uptime-kuma.serviceConfig.Slice = "monitoring.slice";

  # Allow WG peers to reach monitoring UIs on the wg0 interface only.
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 3001 3003 9090 ];
}
