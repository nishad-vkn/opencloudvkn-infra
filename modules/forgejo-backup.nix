{ config, pkgs, ... }:

let
  stageRoot = "/var/backup/forgejo-restic-source";
in
{
  services.restic.backups."forgejo-b2" = {
    repository =
      "s3:https://s3.us-east-005.backblazeb2.com/"
      + "cloudvkn-forgejo-prod-backups/git.cloudvkn.com";

    environmentFile = "/etc/backup/forgejo-b2.env";
    passwordFile = "/etc/backup/restic-forgejo-password";

    # The repository was initialized manually and verified.
    initialize = false;

    paths = [
      stageRoot
    ];

    backupPrepareCommand = ''
      #!${pkgs.runtimeShell}
      set -Eeuo pipefail
      umask 077

      stage="/var/backup/forgejo-restic-source"
      stage_new="/var/backup/forgejo-restic-source.new"
      stage_old="/var/backup/forgejo-restic-source.old"
      forgejo_was_active=0

      restart_forgejo() {
        if [ "$forgejo_was_active" -eq 1 ]; then
          echo "Restarting Forgejo"
          ${pkgs.systemd}/bin/systemctl start forgejo.service
        fi
      }

      trap restart_forgejo EXIT INT TERM HUP

      echo "Checking required services"

      ${pkgs.systemd}/bin/systemctl is-active \
        --quiet postgresql.service

      if ! ${pkgs.systemd}/bin/systemctl is-active \
        --quiet forgejo.service; then
        echo "Forgejo is not active; refusing to create backup" >&2
        exit 1
      fi

      forgejo_was_active=1

      echo "Preparing new staging generation"

      ${pkgs.coreutils}/bin/rm -rf "$stage_new"

      ${pkgs.coreutils}/bin/install \
        -d \
        -o root \
        -g root \
        -m 0700 \
        "$stage_new" \
        "$stage_new/database" \
        "$stage_new/forgejo" \
        "$stage_new/nixos"

      echo "Stopping Forgejo for synchronized snapshot"

      ${pkgs.systemd}/bin/systemctl stop forgejo.service

      echo "Creating PostgreSQL database dump"

      ${pkgs.util-linux}/bin/runuser -u postgres -- \
        ${config.services.postgresql.package}/bin/pg_dump \
          --format=custom \
          --compress=9 \
          forgejo \
          > "$stage_new/database/forgejo.pgdump"

      echo "Creating PostgreSQL role and global-object dump"

      ${pkgs.util-linux}/bin/runuser -u postgres -- \
        ${config.services.postgresql.package}/bin/pg_dumpall \
          --globals-only \
          > "$stage_new/database/postgresql-globals.sql"

      ${pkgs.coreutils}/bin/chmod \
        0600 \
        "$stage_new/database/forgejo.pgdump" \
        "$stage_new/database/postgresql-globals.sql"

      ${pkgs.coreutils}/bin/test \
        -s "$stage_new/database/forgejo.pgdump"

      ${config.services.postgresql.package}/bin/pg_restore \
        --list \
        "$stage_new/database/forgejo.pgdump" \
        >/dev/null

      echo "Copying Forgejo state"

      ${pkgs.rsync}/bin/rsync \
        --archive \
        --hard-links \
        --acls \
        --xattrs \
        --sparse \
        --numeric-ids \
        /var/lib/forgejo/ \
        "$stage_new/forgejo/"

      echo "Copying declarative NixOS configuration"

      ${pkgs.rsync}/bin/rsync \
        --archive \
        --hard-links \
        --acls \
        --xattrs \
        --numeric-ids \
        /etc/nixos/ \
        "$stage_new/nixos/"

      (
        cd "$stage_new/database"

        ${pkgs.coreutils}/bin/sha256sum \
          forgejo.pgdump \
          postgresql-globals.sql \
          > SHA256SUMS
      )

      {
        printf 'backup_time=%s\n' \
          "$(${pkgs.coreutils}/bin/date --iso-8601=seconds)"

        printf 'hostname=%s\n' \
          "$(${pkgs.inetutils}/bin/hostname)"

        printf 'forgejo_state_bytes=%s\n' \
          "$(${pkgs.coreutils}/bin/du -sb /var/lib/forgejo |
             ${pkgs.gawk}/bin/awk '{ print $1 }')"

        printf 'forgejo_database_bytes=%s\n' \
          "$(${pkgs.coreutils}/bin/stat \
             -c '%s' \
             "$stage_new/database/forgejo.pgdump")"

        ${config.services.forgejo.package}/bin/forgejo --version
        ${config.services.postgresql.package}/bin/pg_dump --version
      } > "$stage_new/manifest.txt"

      ${pkgs.coreutils}/bin/chmod \
        0600 \
        "$stage_new/manifest.txt" \
        "$stage_new/database/SHA256SUMS"

      echo "Restarting and validating Forgejo"

      ${pkgs.systemd}/bin/systemctl start forgejo.service

      ${pkgs.systemd}/bin/systemctl is-active \
        --quiet forgejo.service

      forgejo_was_active=0

      # Host secrets and mail data. Copied after Forgejo is back up so
      # they add no git downtime. The restic repository is encrypted.
      # /etc/backup (B2 credentials + restic password) is deliberately
      # excluded: it is needed to open this repository, so keep it offline.
      echo "Copying host secrets and mail data"

      ${pkgs.coreutils}/bin/install \
        -d \
        -o root \
        -g root \
        -m 0700 \
        "$stage_new/host"

      for src in \
        /etc/ssh/ssh_host_ed25519_key \
        /etc/ssh/ssh_host_ed25519_key.pub \
        /etc/wireguard \
        /var/lib/secrets \
        /var/lib/mail-secrets \
        /var/lib/grafana/admin.pass \
        /var/dkim \
        /var/vmail \
        /var/sieve
      do
        if [ -e "$src" ]; then
          ${pkgs.rsync}/bin/rsync \
            --archive \
            --relative \
            --hard-links \
            --acls \
            --xattrs \
            --numeric-ids \
            "$src" \
            "$stage_new/host/"
        else
          echo "WARNING: $src missing; skipped" >&2
        fi
      done

      echo "Publishing completed staging generation"

      ${pkgs.coreutils}/bin/rm -rf "$stage_old"

      if [ -e "$stage" ]; then
        ${pkgs.coreutils}/bin/mv "$stage" "$stage_old"
      fi

      ${pkgs.coreutils}/bin/mv "$stage_new" "$stage"
      ${pkgs.coreutils}/bin/rm -rf "$stage_old"

      trap - EXIT INT TERM HUP

      echo "Forgejo staging snapshot completed successfully"
    '';

    extraBackupArgs = [
      "--host=git.cloudvkn.com"
      "--tag=forgejo"
      "--tag=production"
      "--cleanup-cache"
    ];

    pruneOpts = [
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
      "--keep-yearly 3"
      "--group-by host,paths,tags"
    ];

    runCheck = true;

    checkOpts = [
      "--with-cache"
    ];

    timerConfig = {
      # Existing PostgreSQL local backup runs at 03:15.
      OnCalendar = "*-*-* 03:45:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
      AccuracySec = "1m";
    };

    createWrapper = true;
  };

  systemd.services."restic-backups-forgejo-b2" = {
    requires = [
      "postgresql.service"
    ];

    after = [
      "postgresql.service"
    ];

    serviceConfig = {
      UMask = "0077";
      Nice = 10;
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
      RuntimeMaxSec = "2h";
    };
  };
}
