# Placeholder hardware configuration for the Raspberry Pi Zero 2 W (aarch64).
#
# This file is NOT auto-generated for this host because the config is authored
# off-device. After first boot, regenerate it on the Pi with
# `nixos-generate-config`, or build a bootable SD image (see README) which
# supplies its own filesystem/bootloader layout.
{ lib, ... }:
{
  # The Pi boots via U-Boot + extlinux, not GRUB/systemd-boot.
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" "mmc_block" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
