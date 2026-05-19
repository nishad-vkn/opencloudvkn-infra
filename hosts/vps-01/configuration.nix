{ config, pkgs, lib, ... }:

{
  networking.hostName = "vps-01";
  networking.domain = "opencloudvkn.com";

  time.timeZone = "Asia/Dubai";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  system.stateVersion = "25.11";

  boot.kernelParams = [ "net.ifnames=0" "biosdevname=0" ];

  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.enableIPv6 = true;

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
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
