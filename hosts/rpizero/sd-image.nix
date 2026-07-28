{ modulesPath, ... }:
{
  # SD-image build entry point for the Raspberry Pi 4B. The sd-image-aarch64 module
  # supplies the root filesystem (label NIXOS_SD), the extlinux/U-Boot
  # bootloader and the image-builder itself, so we do NOT import
  # hardware-configuration.nix here (that would clash on those definitions).
  #
  # Build it (with an aarch64 builder or binfmt emulation registered) via:
  #   nix build .#nixosConfigurations.rpizero-sd.config.system.build.sdImage
  # (the `rpizero-sd` flake output name is kept for continuity; it now targets
  # the Pi 4B.)
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    ./configuration.nix
  ];
}
