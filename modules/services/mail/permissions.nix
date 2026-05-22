{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.mail.enable {
  # Keep the secrets dir non-listable by non-root, while leaving the password
  # file mode untouched so Dovecot's passdb read keeps working (0751 grants
  # traverse, not list).
  systemd.tmpfiles.rules = [
    "d /var/lib/mail-secrets 0751 root root - -"
  ];
}
