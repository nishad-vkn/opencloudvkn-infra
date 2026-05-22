{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf (cfg.services.mail.enable && cfg.services.mail.antivirus.enable) {
  mailserver.virusScanning = true;

  # Hard resource cap so ClamAV's signature DB can never threaten the box.
  systemd.slices.clamav = {
    description = "ClamAV resource slice (capped)";
    sliceConfig = {
      MemoryHigh = "1200M";
      MemoryMax = "1500M";
      CPUQuota = "50%";
    };
  };

  systemd.services.clamav-daemon.serviceConfig = {
    Slice = "clamav.slice";
    Restart = lib.mkDefault "on-failure";
  };
  systemd.services.clamav-freshclam.serviceConfig.Slice = "clamav.slice";
}
