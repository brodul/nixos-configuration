{
  description = "NixOS configs for brodul machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      mkHost = { system ? "x86_64-linux", hostDir }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            hostDir
            home-manager.nixosModules.default
          ];
        };
    in
    {
      nixosConfigurations = {
        vipera = mkHost { hostDir = ./hosts/vipera; };
        rpizero = mkHost { system = "aarch64-linux"; hostDir = ./hosts/rpizero; };
        # Flashable SD image for the Raspberry Pi 4B. Build with:
        #   nix build .#nixosConfigurations.rpizero-sd.config.system.build.sdImage
        rpizero-sd = mkHost { system = "aarch64-linux"; hostDir = ./hosts/rpizero/sd-image.nix; };
        # laptop = mkHost { hostDir = ./hosts/laptop; };
      };
    };
}
