{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.forgejo.enable {
  systemd.slices.git = {
    description = "CloudVKN git slice";
    sliceConfig = { MemoryHigh = "1500M"; MemoryMax = "2G"; CPUQuota = "150%"; };
  };

  systemd.services.forgejo.serviceConfig = {
    Slice = "git.slice";
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
    # ProtectSystem strict + writable state/runtime paths only.
    ProtectSystem = "strict";
    ReadWritePaths = [ "/var/lib/forgejo" "/run/postgresql" ];
  };
}
