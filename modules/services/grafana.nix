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
        disable_gravatar = true;
        cookie_secure = false;   # http over wg; no public TLS
      };
      analytics.reporting_enabled = false;
      analytics.check_for_updates = false;
      users.allow_sign_up = false;
      users.allow_org_create = false;

      # Email via local Postfix as support@ (alerts, invites, resets).
      smtp = {
        enabled = true;
        host = "127.0.0.1:25";
        from_address = "support@${cfg.domain}";
        from_name = "CloudVKN Grafana";
        skip_verify = true;
      };
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
      # Auto-load the Node Exporter Full dashboard (ID 1860) + others.
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = "/var/lib/grafana/dashboards";
        }
      ];
    };
  };

  # Place dashboard JSON files for auto-provisioning.
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/dashboards 0750 grafana grafana - -"
  ];

  systemd.services.grafana = {
    after = [ "wireguard-wg0.service" "network-online.target" "postfix.service" ];
    wants = [ "network-online.target" ];
    serviceConfig.Slice = "monitoring.slice";
  };

  # Open wg0 port (also in firewall.nix; harmless if duplicated via mkAfter).
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 3003 ];
}
