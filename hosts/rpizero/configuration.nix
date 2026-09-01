{ pkgs, lib, inputs, ... }:
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
  # KERNEL: we deliberately stay on the stock generic sd-image-aarch64 (mainline)
  # kernel, which is served from the binary cache — no multi-hour on-device or
  # emulated compile. Trade-off: there is NO hardware V4L2 video decode (the
  # bcm2835-codec / rpivid decode nodes only exist in the downstream RPi kernel),
  # so video decode stays on the CPU. YouTube is held to H.264 @ 720p via
  # enhanced-h264ify to keep that tolerable. (An earlier revision cross-compiled
  # the RPi kernel for HW decode; removed by choice to keep builds fast and
  # cache-backed. See git history if HW decode is ever wanted again.)
  imports = [
    ../../modules/common.nix
    ../../modules/remote-access.nix
    ../../modules/office.nix
    ../../modules/theme.nix
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
    # US is the default (first in the list); Slovenian is available as a second
    # group for typing č/š/ž/€. We deliberately set NO xkb group-toggle option
    # (Alt+Shift and friends clash with app shortcuts); the layout is flipped
    # instead by an i3 keybinding (Mod4+Space -> `xkb-switch -n`), see
    # users/brodul/home-rpizero.nix.
    xkb.layout = "us,si";
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
    # If a file home-manager wants to manage already exists (e.g. a hand-edited
    # ~/.config/i3/config), back it up instead of aborting activation with
    # "Existing file would be clobbered" (which silently leaves the whole user
    # profile — mpv, firefox config, i3 — unactivated).
    backupFileExtension = "hmbak";
  };

  system.stateVersion = "23.11";
}
