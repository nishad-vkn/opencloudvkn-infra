{
  description = "cloudvkn NixOS VPS profile";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
    mailserver.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, disko, mailserver, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.vps-01 = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          mailserver.nixosModules.mailserver

          ./cloudvkn.nix
          ./lib/acme.nix
          ./modules/lib/mail-submission.nix

          ./hosts/vps-01/disko.nix
          ./hosts/vps-01/hardware-configuration.nix
          ./hosts/vps-01/configuration.nix

          ./modules/base.nix
          ./modules/hardening.nix
          ./modules/users.nix
          ./modules/ssh.nix
          ./modules/firewall.nix
          ./modules/webserver.nix
          ./modules/wireguard.nix          # UNCHANGED — your 7 peers

          ./modules/postgresql.nix
          ./modules/services/git
          ./modules/services/cache
          ./modules/services/monitoring.nix
          ./modules/services/prometheus.nix
          ./modules/services/grafana.nix
          ./modules/services/web-fail2ban.nix
          ./modules/services/mail

          # Enable the services here (central toggles).
          {
            cloudvkn.services.forgejo.enable = true;
            cloudvkn.services.cache.enable = true;
            cloudvkn.services.monitoring.enable = true;
            cloudvkn.services.mail = {
              enable = true;
              fail2ban.enable = true;
              antivirus.enable = true;
              backup.enable = false;
              reporting.enable = false;
            };
          }
        ];
      };
    };
}
