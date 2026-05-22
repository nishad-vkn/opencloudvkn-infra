{ ... }:
{
  imports = [
    ./core.nix
    ./permissions.nix
    ./antispam.nix
    ./hardening.nix
    ./fail2ban.nix
    ./antivirus.nix
    ./backup.nix
    ./reporting.nix
  ];
}
