{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf (cfg.services.mail.enable && cfg.services.mail.antivirus.enable) {
  mailserver.virusScanning = true;

  # NixOS already defines "system-clamav.slice" (with its own description).
  # Only add resource caps to it — don't redefine description/other fields.
  systemd.slices."system-clamav".sliceConfig = {
    MemoryHigh = "1200M";
    MemoryMax = "1500M";
    CPUQuota = "50%";
  };

  systemd.services.clamav-daemon.serviceConfig.Restart = lib.mkDefault "on-failure";
}
