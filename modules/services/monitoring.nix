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

  # NixOS's uptime-kuma module already applies strong systemd hardening
  # (ProtectControlGroups, ProtectSystem, etc.). Don't redeclare those —
  # only attach our resource slice.
  systemd.services.uptime-kuma.serviceConfig.Slice = "monitoring.slice";
}
