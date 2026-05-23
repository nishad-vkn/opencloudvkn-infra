{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.monitoring.enable {
  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "0.0.0.0";   # firewall restricts to wg0; localhost for Grafana
    globalConfig.scrape_interval = "30s";
    retentionTime = "30d";

    # Prometheus uses --no-<flag> for boolean false, NOT --flag=false.
    extraFlags = [
      "--no-web.enable-lifecycle"
      "--no-web.enable-admin-api"
      "--storage.tsdb.retention.size=2GB"
    ];

    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9100;
      enabledCollectors = [ "systemd" "processes" ];
      disabledCollectors = [ "arp" "bcache" "bonding" "infiniband" "ipvs" "nfs" "nfsd" "xfs" "zfs" ];
    };

    scrapeConfigs = [
      { job_name = "node"; static_configs = [ { targets = [ "127.0.0.1:9100" ]; } ]; }
      { job_name = "rspamd"; static_configs = [ { targets = [ "127.0.0.1:11334" ]; } ]; }
    ];
  };

  systemd.services.prometheus.serviceConfig.Slice = "monitoring.slice";
  systemd.services.prometheus-node-exporter.serviceConfig.Slice = "monitoring.slice";
}
