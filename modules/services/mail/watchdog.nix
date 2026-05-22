{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
  alertTo = "${cfg.adminUser}@${cfg.domain}";
  alertFrom = "support@${cfg.domain}";

  # Sends an alert email about a failed unit via local Postfix.
  notifyScript = pkgs.writeShellScript "mail-unit-failed" ''
    UNIT="$1"
    {
      echo "From: ${alertFrom}"
      echo "To: ${alertTo}"
      echo "Subject: [CloudVKN ALERT] $UNIT failed on $(${pkgs.nettools}/bin/hostname)"
      echo
      echo "Unit $UNIT entered a failed state at $(date)."
      echo
      ${pkgs.systemd}/bin/systemctl status "$UNIT" --no-pager -n 30 2>&1 || true
    } | ${pkgs.system-sendmail}/bin/sendmail -t
  '';
in
lib.mkIf cfg.services.mail.enable {
  # Per-unit OnFailure -> alert service.
  systemd.services."alert@" = {
    description = "Email alert that %i failed";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${notifyScript} %i";
    };
  };

  # Wire each mail unit to trigger the alert on failure.
  systemd.services.postfix.unitConfig.OnFailure = "alert@postfix.service";
  systemd.services.dovecot.unitConfig.OnFailure = "alert@dovecot.service";
  systemd.services.rspamd.unitConfig.OnFailure = "alert@rspamd.service";
  systemd.services.redis-rspamd.unitConfig.OnFailure = "alert@redis-rspamd.service";
}
