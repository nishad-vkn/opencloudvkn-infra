{
  description = "cloudvkn base NixOS VPS profile";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, disko, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.vps-01 = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./hosts/vps-01/disko.nix
          ./hosts/vps-01/hardware-configuration.nix
          ./hosts/vps-01/configuration.nix
          ./modules/base.nix
          ./modules/hardening.nix
          ./modules/ssh.nix
          ./modules/firewall.nix
          ./modules/caddy.nix
          ./modules/wireguard.nix
          ./modules/postgresql.nix
          ./modules/forgejo.nix
          ./modules/cache.nix
        ];
      };
    };
}
