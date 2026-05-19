{ config, pkgs, lib, ... }:

{
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      22
      80
      443
    ];

    allowedUDPPorts = [ ];

    allowPing = true;

    logRefusedConnections = true;
    logRefusedPackets = false;

    extraCommands = ''
      iptables -A INPUT -m conntrack --ctstate INVALID -j DROP || true
      ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP || true
    '';
  };
}
