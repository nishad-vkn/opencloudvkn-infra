{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.monitoring.enable {
  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "10.88.0.1";     # WireGuard-only
    globalConfig.scrape_interval = "30s";
    retentionTime = "30d";

    # Disable remote-write receiver + admin API (attack surface).
    extraFlags = [
      "--web.enable-lifecycle=false"
      "--web.enable-admin-api=false"
      "--storage.tsdb.retention.size=2GB"
    ];

    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";    # localhost only; Prometheus scrapes locally
      port = 9100;
      enabledCollectors = [ "systemd" "processes" ];
      # Trim default collectors we don't need (smaller surface, less noise).
      disabledCollectors = [ "arp" "bcache" "bonding" "infiniband" "ipvs" "nfs" "nfsd" "xfs" "zfs" ];
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [ { targets = [ "127.0.0.1:9100" ]; } ];
      }
      {
        job_name = "rspamd";
        static_configs = [ { targets = [ "127.0.0.1:11334" ]; } ];
      }
    ];
  };

  systemd.services.prometheus.serviceConfig.Slice = "monitoring.slice";
  systemd.services.prometheus-node-exporter.serviceConfig.Slice = "monitoring.slice";
}
