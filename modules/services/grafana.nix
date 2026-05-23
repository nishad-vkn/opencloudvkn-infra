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
        enable_gzip = true;
      };

      security = {
        admin_user = "nali";
        admin_password = "$__file{/var/lib/grafana/admin.pass}";
        disable_gravatar = true;
        cookie_secure = false;
        cookie_samesite = "strict";
        content_security_policy = true;
      };

      users = {
        allow_sign_up = false;
        allow_org_create = false;
        auto_assign_org = true;
        default_theme = "dark";
      };

      "auth.anonymous".enabled = false;
      "auth.basic".enabled = true;

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
        check_for_plugin_updates = false;
        feedback_links_enabled = false;
      };

      news.news_feed_enabled = false;
      snapshots.external_enabled = false;

      smtp = {
        enabled = true;
        host = "127.0.0.1:25";
        from_address = "support@${cfg.domain}";
        from_name = "CloudVKN Grafana";
        skip_verify = true;
      };

      log.level = "warn";
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://10.88.0.1:9090";
          isDefault = true;
          jsonData.timeInterval = "30s";
        }
      ];
    };
  };

  systemd.services.grafana = {
    after = [ "wireguard-wg0.service" "network-online.target" "postfix.service" ];
    wants = [ "network-online.target" ];
    serviceConfig.Slice = "monitoring.slice";
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 3003 ];
}
