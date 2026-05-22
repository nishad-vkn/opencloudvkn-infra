{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
  alertTo = "${cfg.adminUser}@${cfg.domain}";
  alertFrom = "support@${cfg.domain}";
  ip = "209.182.234.229";
  revIp = "229.234.182.209";  # reversed for DNSBL lookup

  checkScript = pkgs.writeShellScript "mail-healthcheck" ''
    set -uo pipefail
    PROBLEMS=""

    # 1. Queue depth (deferred mail piling up = delivery broken)
    QLEN=$(${pkgs.postfix}/bin/mailq | grep -c '^[A-F0-9]' || true)
    if [ "''${QLEN:-0}" -gt 50 ]; then
      PROBLEMS="$PROBLEMS\n- Mail queue is high: $QLEN messages deferred."
    fi

    # 2. Core services active?
    for svc in postfix dovecot rspamd; do
      if ! ${pkgs.systemd}/bin/systemctl is-active --quiet $svc; then
        PROBLEMS="$PROBLEMS\n- Service $svc is NOT active."
      fi
    done

    # 3. Disk space on /var (mail storage)
    USEPCT=$(${pkgs.coreutils}/bin/df --output=pcent /var | tail -1 | tr -dc '0-9')
    if [ "''${USEPCT:-0}" -gt 85 ]; then
      PROBLEMS="$PROBLEMS\n- /var disk usage high: ''${USEPCT}%."
    fi

    # 4. Blacklist check (Spamhaus ZEN)
    if ${pkgs.dnsutils}/bin/dig +short ${revIp}.zen.spamhaus.org A | grep -q '127.'; then
      PROBLEMS="$PROBLEMS\n- IP ${ip} is listed on Spamhaus ZEN!"
    fi

    # 5. Cert expiry (<14 days)
    EXP=$(echo | ${pkgs.openssl}/bin/openssl s_client -connect mail.${cfg.domain}:993 -servername mail.${cfg.domain} 2>/dev/null | ${pkgs.openssl}/bin/openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -n "$EXP" ]; then
      EXP_TS=$(${pkgs.coreutils}/bin/date -d "$EXP" +%s 2>/dev/null || echo 0)
      NOW_TS=$(${pkgs.coreutils}/bin/date +%s)
      DAYS=$(( (EXP_TS - NOW_TS) / 86400 ))
      if [ "$DAYS" -lt 14 ]; then
        PROBLEMS="$PROBLEMS\n- TLS cert expires in $DAYS days."
      fi
    fi

    # Alert only if something is wrong.
    if [ -n "$PROBLEMS" ]; then
      {
        echo "From: ${alertFrom}"
        echo "To: ${alertTo}"
        echo "Subject: [CloudVKN ALERT] Mail health check found issues"
        echo
        echo -e "Mail health check at $(date) found:\n$PROBLEMS"
      } | /run/wrappers/bin/sendmail -t
    fi
  '';
in
lib.mkIf cfg.services.mail.enable {
  systemd.services.mail-healthcheck = {
    description = "CloudVKN mail health check";
    serviceConfig = { Type = "oneshot"; ExecStart = checkScript; };
  };
  systemd.timers.mail-healthcheck = {
    description = "Run mail health check periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "*:0/15"; Persistent = true; };
  };
}
