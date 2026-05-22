{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.monitoring.enable {
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "10.88.0.1";
        http_port = 3003;
        domain = "10.88.0.1";
        root_url = "http://10.88.0.1:3003/";
      };
      security = {
        admin_user = "nali";
        admin_password = "$__file{/var/lib/grafana/admin.pass}";
      };
      analytics.reporting_enabled = false;
      users.allow_sign_up = false;
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://10.88.0.1:9090";
          isDefault = true;
        }
      ];
    };
  };

  systemd.services.grafana = {
    after = [ "wireguard-wg0.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Slice = "monitoring.slice";
      # Allow bind to a possibly-not-yet-present address; retry friendly.
      RestartSec = lib.mkForce "5s";
    };
  };
}
