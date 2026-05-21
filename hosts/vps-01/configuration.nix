{ config, pkgs, lib, ... }:
{
  time.timeZone = "Asia/Dubai";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  system.stateVersion = "25.11";

  boot.kernelParams = [ "net.ifnames=0" "biosdevname=0" ];

  networking.useDHCP = false;
  networking.enableIPv6 = true;
  networking.interfaces.eth0 = {
    ipv4.addresses = [ { address = "209.182.234.229"; prefixLength = 24; } ];
    ipv6.addresses = [ { address = "2602:ff16:14:0:1:2b:0:1"; prefixLength = 48; } ];
  };
  networking.defaultGateway = { address = "209.182.234.1"; interface = "eth0"; };
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" ];

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };
}
