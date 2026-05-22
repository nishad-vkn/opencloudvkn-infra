{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.cache.enable {
  systemd.slices.cache = {
    description = "CloudVKN cache slice";
    sliceConfig = { MemoryHigh = "768M"; MemoryMax = "1G"; CPUQuota = "100%"; };
  };

  systemd.services.harmonia.serviceConfig = {
    Slice = "cache.slice";
    NoNewPrivileges = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectHome = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    ProtectProc = "invisible";
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [ "@system-service" "~@privileged" ];
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
    ProtectSystem = "strict";
    # Harmonia reads the nix store (already ro) + its key.
    ReadWritePaths = [ ];
  };
}
