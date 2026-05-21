{ config, pkgs, lib, ... }:

{
  networking.hostName = "vps-01";
  networking.domain = "cloudvkn.com";

  time.timeZone = "Asia/Dubai";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  system.stateVersion = "25.11";

  # Predictable interface name on VPS.
  boot.kernelParams = [ "net.ifnames=0" "biosdevname=0" ];

  # Static networking on the public interface.
  networking.useDHCP = false;
  networking.enableIPv6 = true;

  networking.interfaces.eth0 = {
    ipv4.addresses = [
      { address = "209.182.234.229"; prefixLength = 24; }
    ];
    ipv6.addresses = [
      { address = "2602:ff16:14:0:1:2b:0:1"; prefixLength = 48; }
    ];
  };

  networking.defaultGateway = {
    address = "209.182.234.1";
    interface = "eth0";
  };

  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "eth0";
  };

  # Use Cloudflare + Google DNS (override if you prefer self-hosted later).
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "8.8.8.8"
    "2606:4700:4700::1111"
    "2606:4700:4700::1001"
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  users.mutableUsers = false;

  users.users.nali = {
    isNormalUser = true;
    description = "Nali Admin";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElysVA40MN0V7vo4rG2NngRZGHtJB3+I5Uqg0+XJlnW t14@DESKTOP-BGEPD1V"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
