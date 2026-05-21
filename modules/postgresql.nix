{ config, pkgs, lib, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    # Local-only; nothing binds to the network.
    enableTCPIP = false;

    settings = {
      # Tuned for 8 GB RAM / 2 vCPU, shared with other services.
      max_connections = 100;
      shared_buffers = "1GB";
      effective_cache_size = "3GB";
      maintenance_work_mem = "256MB";
      work_mem = "16MB";
      wal_buffers = "16MB";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      checkpoint_completion_target = 0.9;
      random_page_cost = 1.1;     # SSD
      effective_io_concurrency = 200;
      default_statistics_target = 100;
    };

    # Forgejo gets its own role + db, peer-auth via its system user.
    ensureDatabases = [ "forgejo" ];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
    ];
  };

  # Daily local logical backup of all databases.
  services.postgresqlBackup = {
    enable = true;
    location = "/var/backup/postgresql";
    startAt = "*-*-* 03:15:00";
    compression = "zstd";
  };
}
