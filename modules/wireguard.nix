{ config, pkgs, lib, ... }:

let
  wgInterface = "wg0";
  wgPort = 51820;
  wgSubnet = "10.88.0.0/24";
in
{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [
      wgInterface
    ];
  };

  networking.wireguard.interfaces.${wgInterface} = {
    ips = [
      "10.88.0.1/24"
    ];

    listenPort = wgPort;

    privateKeyFile = "/etc/wireguard/keys/server.key";

    peers = [
      {
        # desktop-admin
        publicKey = "JknaWQuLztvx4Uy0/CIqZc5Ml9px8Dnq68NMLtdM6EQ=";
        allowedIPs = [ "10.88.0.10/32" ];
      }

      {
        # user01
        publicKey = "FkuCHnDqUAlB3ziCEPUQ/pts3Aw8+7Au6ueacLbdW2A=";
        allowedIPs = [ "10.88.0.11/32" ];
      }

      {
        # user02
        publicKey = "sbixprCzBHdxS9GzDA+ignkbVlSmVZ86tnD58KzbNUU=";
        allowedIPs = [ "10.88.0.12/32" ];
      }

      {
        # user03
        publicKey = "mbIu9Myz1xkiZJ3nrMzVIQNHFPB7kcrbCguCx4bhizg=";
        allowedIPs = [ "10.88.0.13/32" ];
      }

      {
        # user04
        publicKey = "vim2SI4VvpJrfwj6VnkccmHRCj0vBczmK7IiZUhsLhw=";
        allowedIPs = [ "10.88.0.14/32" ];
      }

      {
        # user05
        publicKey = "t3CX2t2Du5lHElTtJ5ZMXHPt82avqJHDyoUaeX9hPFE=";
        allowedIPs = [ "10.88.0.15/32" ];
      }

      {
        # user06
        publicKey = "XEHz7OJAUWuScZUB6jHDt4bvkDuB8ZYGZ3EZr3WzsxQ=";
        allowedIPs = [ "10.88.0.16/32" ];
      }
    ];
  };
}
