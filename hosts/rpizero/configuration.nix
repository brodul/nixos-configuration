{ pkgs, inputs, ... }:
{
  # Shared, hardware-agnostic config for the Raspberry Pi 4B. Imported both by
  # the installed system (default.nix, alongside hardware-configuration.nix) and
  # by the SD-image build (sd-image.nix, alongside the sd-image-aarch64 module).
  # Keep bootloader/filesystem definitions OUT of this file — those belong to
  # the hardware/image layer to avoid conflicting option definitions.
  #
  # The Pi 4B is aarch64 with 2–8 GB of RAM, so unlike the Pi Zero 2 W it can
  # comfortably run a full graphical browser; we no longer strip the config for
  # a 512 MB machine.
  #
  # nixos-hardware's raspberry-pi-4 module switches to the downstream RPi kernel,
  # which provides the V4L2 codec drivers (bcm2835-codec -> /dev/video10-12 for
  # H.264, rpivid -> /dev/video19 for HEVC) that the generic sd-image-aarch64
  # kernel lacks. It keeps the same generic-extlinux-compatible bootloader the
  # SD image uses, so it layers cleanly on top of sd-image.nix.
  # NOTE: this changes the kernel, so the next image build may compile/download a
  # different (RPi) kernel; after flashing, verify `ls /dev/video1*` shows the
  # decode nodes.
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ../../modules/common.nix
    ../../modules/remote-access.nix
    ../../modules/office.nix
  ];

  networking.hostName = "rpi4";
  networking.networkmanager.enable = true;
  networking.modemmanager.enable = false;

  time.timeZone = "Europe/Ljubljana";

  # Broadcom WiFi/Bluetooth firmware for the Pi 4B (needed by both the installed
  # system and the SD image).
  hardware.enableRedistributableFirmware = true;

  # Graphical session: lightdm + a bare i3 window manager.
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    windowManager.i3.enable = true;
    displayManager.lightdm.enable = true;
  };

  # Minimal i3 helpers. Firefox is configured per-user in home-manager
  # (users/brodul/home-rpizero.nix) so it can carry the Pi-4 rendering-glitch
  # prefs + the enhanced-h264ify add-on.
  environment.systemPackages = with pkgs; [
    i3status
    dmenu
  ];

  # Printing: CUPS with Gutenprint, which provides drivers for a wide range of
  # OKI laser/LED printers. Adjust `drivers` if your specific OKI model needs a
  # vendor PPD.
  #
  # NOTE: only `gutenprint` here — `gutenprintBin` (cups-gutenprint-binary) is
  # an x86_64-only binary package and fails to evaluate on aarch64, breaking the
  # image build.
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint ];
  };

  # mDNS/DNS-SD so networked (AirPrint/IPP) OKI printers are discovered.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Syncing: run Syncthing as a system service owned by brodul.
  services.syncthing = {
    enable = true;
    user = "brodul";
    group = "users";
    dataDir = "/home/brodul";
    configDir = "/home/brodul/.config/syncthing";
    overrideDevices = false;
    overrideFolders = false;
    openDefaultPorts = true;
    guiAddress = "127.0.0.1:8384";
  };

  # Compressed RAM swap — cheap headroom, still worth keeping on the Pi 4B.
  zramSwap.enable = true;

  users.users.root.initialPassword = "changeme";

  users.users.brodul = {
    initialPassword = "changeme";
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "sudo" "audio" "video" "tty" "lp" "scanner" "networkmanager" ];
    shell = pkgs.zsh;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.brodul = import ../../users/brodul/home-rpizero.nix;
  };

  system.stateVersion = "23.11";
}
