{ config, pkgs, lib, ... }:
{
  networking.firewall = {
    enable = true;

    # Public TCP: SSH, HTTP, HTTPS, Forgejo git-SSH
    allowedTCPPorts = [
      22
      80
      443
      2222
    ];

    # Public WireGuard
    allowedUDPPorts = [
      51820
    ];

    # Internal-only services reachable over the VPN.
    interfaces.wg0.allowedTCPPorts = [
      3001   # Uptime Kuma
    ];

    allowPing = true;
    logRefusedConnections = true;
    logRefusedPackets = false;

    extraCommands = ''
      iptables -A INPUT -m conntrack --ctstate INVALID -j DROP || true
      ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP || true
    '';
  };
}
