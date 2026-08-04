{
  description = "NixOS configs for brodul machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Raspberry Pi hardware profiles. The raspberry-pi-4 module switches the Pi
    # to the downstream RPi kernel, which ships the bcm2835-codec + rpivid V4L2
    # drivers (hardware H.264/HEVC video decode). It keeps the same
    # generic-extlinux-compatible bootloader the sd-image build already uses.
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # x86_64 -> aarch64 cross package set. Used to cross-compile ONLY the Pi's
      # kernel (the RPi kernel is never cached, and building it under QEMU binfmt
      # emulation exhausts/aborts the builder VM). Cross-compiling runs native
      # x86 gcc targeting aarch64, so it builds at native speed. Everything else
      # in the image stays native aarch64 and is substituted from the cache.
      crossPkgsAarch64 = import nixpkgs {
        localSystem = "x86_64-linux";
        crossSystem = "aarch64-linux";
      };
      mkHost = { system ? "x86_64-linux", hostDir }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs crossPkgsAarch64; };
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
