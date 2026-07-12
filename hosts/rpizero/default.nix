{ ... }:
{
  # Installed-system entry point for the Pi Zero 2 W: the on-device hardware
  # layout plus the shared config. Build/apply with:
  #   sudo nixos-rebuild switch --flake /etc/nixos#rpizero
  #
  # To build a flashable SD image on another (x86_64) machine instead, use the
  # `rpizero-sd` output — see hosts/rpizero/sd-image.nix and the README.
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
  ];
}
