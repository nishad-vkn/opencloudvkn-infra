{ config, pkgs, lib, ... }:
{
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      22      # SSH
      80      # HTTP (Caddy, ACME)
      443     # HTTPS (Caddy)
      2222    # Forgejo git-SSH
      25      # SMTP (inbound mail)
      465     # SMTPS (submission, implicit TLS)
      587     # submission (STARTTLS)
      993     # IMAPS
    ];

    allowedUDPPorts = [
      51820   # WireGuard
    ];

    interfaces.wg0.allowedTCPPorts = [
      3001    # Uptime Kuma (VPN only)
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
