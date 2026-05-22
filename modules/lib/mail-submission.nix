{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.mail.enable {
  # Allow local services (127.0.0.1) to inject mail without auth.
  # Single-tenant box: all local processes are trusted.
  services.postfix.settings.main.mynetworks = [ "127.0.0.0/8" "[::1]/128" ];
}
