{ config, lib, ... }:
let
  cfg = config.cloudvkn;
in
lib.mkIf cfg.services.mail.enable {
  # Bound the rspamd Redis. volatile-lru evicts only keys WITH a TTL
  # (greylist/ratelimit/fuzzy), preserving Bayes tokens (no TTL) so learning
  # is never lost to eviction.
  services.redis.servers.rspamd.settings = {
    maxmemory = "256mb";
    maxmemory-policy = "volatile-lru";
  };

  # rspamd action thresholds (these mirror rspamd defaults; adjust later).
  # Greylisting is intentionally NOT forced here to avoid delaying first-contact
  # inbound mail. Bayes auto-learn happens automatically when you move mail
  # to/from the Junk folder.
  services.rspamd.locals = {
    "actions.conf".text = ''
      reject = 15;
      add_header = 6;
    '';
  };
}
