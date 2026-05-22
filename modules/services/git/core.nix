{ config, lib, pkgs, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.forgejo.enable {
  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;
    database = {
      type = "postgres";
      socket = "/run/postgresql";
      name = "forgejo";
      user = "forgejo";
      createDatabase = false;
    };
    stateDir = "/var/lib/forgejo";
    lfs.enable = true;
    settings = {
      DEFAULT.APP_NAME = "CloudVKN Git";

      server = {
        DOMAIN = "git.${cfg.domain}";
        ROOT_URL = "https://git.${cfg.domain}/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        PROTOCOL = "http";
        START_SSH_SERVER = true;
        SSH_DOMAIN = "git.${cfg.domain}";
        SSH_PORT = 2222;
        SSH_LISTEN_HOST = "0.0.0.0";
        SSH_LISTEN_PORT = 2222;
        LANDING_PAGE = "login";        # no public homepage
      };

      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = true;    # nothing visible without login
        DEFAULT_KEEP_EMAIL_PRIVATE = true;
      };

      # Outgoing mail via local Postfix as support@ (system notifications).
      mailer = {
        ENABLED = true;
        PROTOCOL = "sendmail";
        FROM = "support@${cfg.domain}";
        SENDMAIL_PATH = "/run/wrappers/bin/sendmail";
      };

      "cron.update_checker".ENABLED = false;
      session.COOKIE_SECURE = true;
      log.LEVEL = "Warn";
      security.INSTALL_LOCK = true;
      other.SHOW_FOOTER_VERSION = false;
    };
  };
}
