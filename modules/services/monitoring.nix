{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.monitoring.enable {
  services.uptime-kuma = {
    enable = true;
    settings = { HOST = "10.88.0.1"; PORT = "3001"; };
  };
  # First-run admin account is created in the UI; use support@cloudvkn.com
  # as the ops login there. Notifications configured in-UI to support@.
}
