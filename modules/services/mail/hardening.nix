{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.mail.enable {
  # Resource slice for the mail stack (carrier-grade governance). Limits are
  # generous so they never bite under normal load, but cap a runaway.
  systemd.slices.mailstack = {
    description = "CloudVKN mail stack resource slice";
    sliceConfig = {
      MemoryHigh = "3G";
      MemoryMax = "3500M";
      CPUQuota = "200%";
    };
  };

  systemd.services.postfix.serviceConfig.Slice = "mailstack.slice";
  systemd.services.dovecot.serviceConfig.Slice = "mailstack.slice";
  systemd.services.rspamd.serviceConfig.Slice = "mailstack.slice";
  systemd.services.redis-rspamd.serviceConfig.Slice = "mailstack.slice";
}
