{ config, pkgs, lib, ... }:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];

      trusted-users = [
        "root"
        "nali"
      ];

      allowed-users = [
        "root"
        "nali"
      ];

      require-sigs = true;
      auto-optimise-store = true;

      substituters = [
        "https://cache.nixos.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  nixpkgs.config.allowUnfree = false;

  environment.systemPackages = with pkgs; [
    vim
    nano
    git
    curl
    wget
    jq
    htop
    lsof
    psmisc
    tcpdump
    nmap
    nftables
    dnsutils
    traceroute
    mtr
    rsync
    unzip
    pciutils
    usbutils
    wireguard-tools
    qrencode
  ];

  services.timesyncd.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=30day
    Compress=yes
  '';

  documentation.nixos.enable = false;
}
