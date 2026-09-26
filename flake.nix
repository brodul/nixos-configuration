{
  description = "NixOS configs for brodul machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Experimental native PBS package + module. Not following our nixpkgs on
    # purpose: its own pin is what the awildleon-nixos-pbs Cachix is built from.
    pbs.url = "github:AWildLeon/nixos-pbs";
  };

  outputs = { self, nixpkgs, home-manager, disko, deploy-rs, pbs, ... }@inputs:
    let
      mkHost = { system ? "x86_64-linux", hostDir, extraModules ? [ ] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            hostDir
            home-manager.nixosModules.default
          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        vipera = mkHost { hostDir = ./hosts/vipera; };
        plumbus = mkHost {
          hostDir = ./hosts/plumbus;
          extraModules = [
            disko.nixosModules.disko
            pbs.nixosModules.proxmox-backup-server
          ];
        };
        # laptop = mkHost { hostDir = ./hosts/laptop; };
      };

      # Ongoing updates for remote machines: `nix run github:serokell/deploy-rs -- .#plumbus`
      deploy.nodes.plumbus = {
        hostname = "plumbus.example.org"; # TODO: VPS address or DNS name
        profiles.system = {
          sshUser = "root";
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.plumbus;
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
