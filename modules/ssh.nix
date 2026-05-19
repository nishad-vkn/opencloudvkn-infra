{ config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;

    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;

      AllowUsers = [ "nali" ];

      X11Forwarding = false;
      AllowTcpForwarding = "no";
      AllowAgentForwarding = "no";
      PermitTunnel = "no";
      GatewayPorts = "no";

      ClientAliveInterval = 120;
      ClientAliveCountMax = 2;
      LoginGraceTime = 30;
      MaxAuthTries = 3;
      MaxSessions = 5;

      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
      ];

      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];

      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
      ];
    };
  };
}
