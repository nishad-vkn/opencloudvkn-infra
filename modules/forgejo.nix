{ config, pkgs, lib, ... }:
{
  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;

    database = {
      type = "postgres";
      socket = "/run/postgresql";
      name = "forgejo";
      user = "forgejo";
      createDatabase = false;   # postgresql.nix already creates it
    };

    # Local state on the big root fs.
    stateDir = "/var/lib/forgejo";

    lfs.enable = true;

    settings = {
      DEFAULT = {
        APP_NAME = "CloudVKN Git";
      };

      server = {
        DOMAIN = "git.cloudvkn.com";
        ROOT_URL = "https://git.cloudvkn.com/";
        # Forgejo HTTP listens only on localhost; Caddy fronts it.
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        PROTOCOL = "http";

        # Built-in SSH server for git push/pull over SSH.
        START_SSH_SERVER = true;
        SSH_DOMAIN = "git.cloudvkn.com";
        SSH_PORT = 2222;
        SSH_LISTEN_HOST = "0.0.0.0";
        SSH_LISTEN_PORT = 2222;
      };

      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = false;
      };

      # Don't phone home / no built-in updater (NixOS manages the binary).
      "cron.update_checker".ENABLED = false;

      session.COOKIE_SECURE = true;

      log.LEVEL = "Warn";

      # Sane security defaults.
      security.INSTALL_LOCK = true;
      other.SHOW_FOOTER_VERSION = false;
    };
  };
}
