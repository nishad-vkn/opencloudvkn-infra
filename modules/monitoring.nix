{ config, pkgs, lib, ... }:
{
  services.uptime-kuma = {
    enable = true;
    settings = {
      # Bind to the WireGuard interface IP only — never public.
      HOST = "10.88.0.1";
      PORT = "3001";
    };
  };
}
