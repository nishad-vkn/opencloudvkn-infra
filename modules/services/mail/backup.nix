{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf (cfg.services.mail.enable && cfg.services.mail.backup.enable) {
  mailserver.borgbackup = {
    enable = true;
    repoLocation = "/var/borgbackup";
    encryption = {
      method = "repokey-blake2";
      passphraseFile = "/var/lib/mail-secrets/borg.pass";
    };
    compression = { method = "zstd"; level = 9; };
    startAt = "daily";
    locations = [
      config.mailserver.storage.path   # /var/vmail
      "/var/dkim"                       # DKIM private keys
    ];
  };
}
