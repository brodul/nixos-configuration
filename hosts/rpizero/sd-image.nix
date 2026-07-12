{ modulesPath, ... }:
{
  # SD-image build entry point for the Pi Zero 2 W. The sd-image-aarch64 module
  # supplies the root filesystem (label NIXOS_SD), the extlinux/U-Boot
  # bootloader and the image-builder itself, so we do NOT import
  # hardware-configuration.nix here (that would clash on those definitions).
  #
  # Build it (with an aarch64 builder or binfmt emulation registered) via:
  #   nix build .#nixosConfigurations.rpizero-sd.config.system.build.sdImage
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    ./configuration.nix
  ];
}
