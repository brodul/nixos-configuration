{ pkgs, lib, inputs, crossPkgsAarch64, ... }:
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
  # NOTE: this changes the kernel. The RPi kernel is NOT in the binary cache
  # (even nixpkgs' linuxPackages_rpi4 shows "will be built"), so it compiles from
  # source. Do that on a NATIVE aarch64 machine (or a native aarch64 remote
  # builder) — compiling it under QEMU binfmt emulation in the x86_64 builder VM
  # exhausted resources and aborted the VM. After flashing/activating, verify
  # `ls /dev/video1*` shows the decode nodes (video10-12 = H.264, video19 = HEVC).
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ../../modules/common.nix
    ../../modules/remote-access.nix
    ../../modules/office.nix
  ];

  # Cross-compile the kernel instead of emulating it. nixos-hardware sets its
  # kernel with lib.mkDefault, so this plain assignment overrides it. We use the
  # cross-built (x86 host -> aarch64 target) RPi kernel, which builds at native
  # x86 speed rather than crawling (and crashing the VM) under QEMU emulation.
  # The rest of the image is untouched aarch64, substituted from the cache.
  #
  # linux_rpi4 already enables HEVC hardware decode (VIDEO_RPI_HEVC_DEC=m); we
  # additionally turn on the VideoCore H.264 M2M codec (VIDEO_BCM2835_CODEC).
  # Its dependencies (BCM2835_VCHIQ, VCHIQ_MMAL, VC_SM_CMA) are already set in
  # the linux_rpi4 config, so only the codec symbol itself needs enabling.
  #
  # This hardware decode is exposed via V4L2. It is consumed by:
  #   - mpv / gstreamer: the reliable path (`mpv <youtube-url>` via yt-dlp) ->
  #     smooth 1080p.
  #   - Firefox 116+ (ESR 140 here): decodes H.264 via V4L2-M2M directly (bug
  #     1833354), NOT VA-API. Enabled with media.hardware-video-decoding.
  #     force-enabled in home-rpizero.nix. Known to be finicky in practice, so
  #     it's verified on-device (about:support), not assumed.
  # Either way YouTube must be H.264 (enhanced-h264ify); VP9/AV1 have no HW path.
  boot.kernelPackages = crossPkgsAarch64.linuxPackagesFor (
    crossPkgsAarch64.linux_rpi4.override (old: {
      structuredExtraConfig = (old.structuredExtraConfig or { }) // (
        with crossPkgsAarch64.lib.kernel; {
          # Correct Kconfig symbol is VIDEO_CODEC_BCM2835 (verified from the RPi
          # kernel source: drivers/staging/vc04_services/bcm2835-codec/Kconfig).
          # An unknown symbol is silently dropped, so the exact name matters.
          # Deps (MEDIA_SUPPORT, VIDEO_DEV, ARCH_BCM2835=y) are already met.
          VIDEO_CODEC_BCM2835 = module;
          # The linux_rpi4 config builds ~20k modules WITH BTF + debug info,
          # which bloats the build tree to tens of GB (overflowed the builder's
          # disk) and adds a slow pahole BTF pass per module. None of it is
          # needed on a media Pi, so disable it: far smaller/faster build, same
          # runtime behaviour. mkForce because the base config enables them.
          DEBUG_INFO_BTF = crossPkgsAarch64.lib.mkForce no;
          DEBUG_INFO = crossPkgsAarch64.lib.mkForce no;
        }
      );
    })
  );

  # The sd-image module force-enables hardware.enableAllHardware, pulling in the
  # generic "all-hardware" initrd module list (dw-hdmi, dw-mipi-dsi, SCSI RAID,
  # …). That list assumes the mainline aarch64 kernel; our RPi kernel builds
  # HDMI via vc4 (built-in) and never builds dw-hdmi, so the module-shrink step
  # fails with "Module dw-hdmi not found". The Pi doesn't need that broad list —
  # its SD controller (MMC_BCM2835) and ext4 are built into the RPi kernel — so
  # disable it. (nixos-hardware still supplies the Pi's own initrd modules.)
  hardware.enableAllHardware = lib.mkForce false;

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
