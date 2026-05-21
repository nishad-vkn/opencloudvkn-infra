{ config, pkgs, lib, ... }:

{
  networking.firewall = {
    enable = true;

    # Public HTTPS services only
    allowedTCPPorts = [
      80
      443
      22
      2222
    ];

    # Public WireGuard
    allowedUDPPorts = [
      51820
    ];

    # SSH only through WireGuard
    #interfaces.wg0.allowedTCPPorts = [
    #  22
    #];

    allowPing = true;

    logRefusedConnections = true;
    logRefusedPackets = false;

    extraCommands = ''
      iptables -A INPUT -m conntrack --ctstate INVALID -j DROP || true
      ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP || true
    '';
  };
}
