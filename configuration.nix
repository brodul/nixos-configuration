# Edit this configuration file to define what should be installed on
# the system.  Help is available in the configuration.nix(5) man page
# or the NixOS manual available on virtual console 8 (Alt+F8).

{ config, pkgs, lib, ... }:

{

  imports = [
  <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  # Users and groups
  users = {
    extraUsers = {
      brodul = {
        uid = 1000;
        isNormalUser = true;
        extraGroups=[
        "docker" "tty" "vboxusers" "networkmanager"
        "wheel" "dialout" "scanner" "lp" "audio" "wireshark"];
        shell = "/run/current-system/sw/bin/zsh";
      };
    };

  };



  # Timezone
  time.timeZone = "Europe/Ljubljana";

  programs.wireshark.enable= true;

  nix.trustedUsers = [ "root" "brodul"];

  # Virtualization

  virtualisation = {
    virtualbox.host.enable = true;
    docker.enable = true;
  };

  hardware = {
    opengl.enable = true;
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
    sane.enable = true;
  };

  services = {

    xserver = {
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };

    nixosManual.showManual = true;

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    printing.enable = true;
    printing.drivers = [ pkgs.foomatic_filters pkgs.foo2zjs ];

    # Enable the X11 windowing system.
    xserver.enable = true;
    xserver.layout = "us";
    xserver.synaptics.enable = true;
    xserver.displayManager.lightdm.enable = true;
    xserver.desktopManager.xfce.enable = true;
    xserver.windowManager.i3.enable = true;
    xserver.windowManager.i3.extraPackages = with pkgs; [i3status dmenu i3lock i3blocks];
   # xserver.windowManager.i3.configFile = "/home/brodul/.i3/config";

    elasticsearch.enable = false;
    mongodb.enable = false;

    postgresql.enable = false;
    postgresql.package = pkgs.postgresql96;
  };


  ###
  # Boot
  ###

  # Kernel modules
  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
    kernelModules = [ "kvm-intel" "fuse" ];
    blacklistedKernelModules = [ "pcspkr" "snd_soc_skl" ];

    kernel.sysctl = {"net.ipv4.ip_forward" = 1;};

    # Use the GRUB 2 boot loader.
    loader.grub = {
      enable = true;
      version = 2;
      enableCryptodisk = true;

      # Define on which hard drive you want to install Grub.
      device = "/dev/sda";
    };

    cleanTmpDir = true;
    tmpOnTmpfs = true;

    initrd.preLVMCommands = ''
    echo '  _                   _       _ '
    echo ' | |                 | |     | |'
    echo ' | |__  _ __ ___   __| |_   _| |'
    echo ' | `_ \| `__/ _ \ / _` | | | | |'
    echo ' | |_) | | | (_) | (_| | |_| | |'
    echo ' |_.__/|_|  \___/ \__,_|\__,_|_|'
    echo '                                '
    echo
    echo ' Additional passphrase needed ... '
    echo
    '';

    initrd.luks.devices = [
      {
        device = "/dev/mapper/all-crypted";
        name = "cryptedroot";
        preLVM=false;}
    ];

    extraModprobeConfig = ''
      options snd slots=snd-hda-intel
    '';

  };

  fileSystems."/".device = "/dev/mapper/cryptedroot";
  fileSystems."/boot".device = "/dev/disk/by-label/boot";


  networking = {
    hostName = "blackhole";
    networkmanager.enable = true;
    firewall.enable = false; #TODO
  };


  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
    corefonts # Microsoft free fonts
    inconsolata # monospaced
    ubuntu_font_family
    dejavu_fonts
    fira
    fira-code
    ];
  };


  ###
  # Packages
  ###

  nixpkgs.config = {
    allowUnfree = true;
    firefox = {
      jre = false;
      enableGoogleTalkPlugin = true;
      enableAdobeFlash = false;
    };

    chromium = {
      # enablePepperFlash = false;
      # enablePepperPDF = true;
      # jre = false;
    };

  };


  environment.systemPackages = with pkgs; [
  (import (builtins.fetchTarball {
    url = "https://github.com/domenkozar/proxsign-nix/archive/cc26bee496facdb61c2cbb2bcfef55e167d4a85b.tar.gz";
    sha256 = "0smhpz7hw382mlin79v681nws4pna5bdg0w8cjb4iq23frnb5dw6";
  }))
  foo2zjs
  # firmware
  upower

  # generally useful tools
  alsaUtils
  acpitool

  cpio
  imagemagick
  mysql
  nixops
  openssl
  #rabbitmq_server
  rtorrent
  socat
  smartmontools
  # yafc
  zlib
  zip
  zsh
  # virtualbox

  #
  links2
  w3m
  wgetpaste
  pwgen
  curl
  vim_configurable
  gitFull
  mercurial
  autojump # doesnt keep history
  anki
  sqlite
  sshfsFuse
  fuse
  ncmpcpp
  # mplayer2
  jwhois
  dos2unix
  gnumake
  libevent
  vifm
  patchelf
  reaverwps
  unetbootin
  gcc
  sysstat
  nixops
  speedtest_cli
  mosh

  # sys tools
  rmlint
  extundelete
  hdparm
  tmux
  gnupg
  wget
  nmap
  ncdu
  telnet
  unzip
  unrar
  psmisc

  # X apps
  rxvt_unicode
  # TODO: make it a floating window so it's not annoying
  p7zip
  gmpc
  pavucontrol
  pa_applet
  dunst  # notifications
  #xfce.thunar_archive_plugin
  #arandr

  deluge
  #gnucash
  gimp
  calibre
  skype
  # dropbox
  libreoffice
  vlc

  evince
  wine
  networkmanagerapplet
  thunderbird

  # browsers
  firefoxWrapper
  chromium

  # games
  #spring
  #springLobby
  #teeworlds
  #openra
  #xonotic

  # postgresql
  pgadmin

  # development
  /* nodePackages.jshint */

  virtualbox
  # python stuff
  # cython
  python27Full
  python3
  pythonPackages.virtualenv
  pythonPackages.flake8
  pythonPackages.pillow
  #pythonPackages.bpython

  # Virtualization


  # lxc
  debootstrap
  lxc

  # bluetooth
  bluez

  ];

  ###
  # Hacking
  ####

  # system.activationScripts.bin_lib_links = ''
  # mkdir -p /usr/lib
  # ln -fs ${pkgs.xlibs.libX11}/lib/libX11.so.6 /usr/lib/libX11.so.6
  # '';


  services.udev.extraRules = ''
  # digispark
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="16d0", ATTRS{idProduct}=="0753", MODE:="0666"
  KERNEL=="ttyACM*", ATTRS{idVendor}=="16d0", ATTRS{idProduct}=="0753", MODE:="0666", ENV{ID_MM_DEVICE_IGNORE}="1"
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="16d0", ATTRS{idProduct}=="0753", SYMLINK+="ttyACM%n"
  # backup usb
  # ACTION=="add", SUBSYSTEM=="usb_device", ATTRS{idVendor}=="05dc", ATTRS{idProduct}=="a838", RUN+="bash /home/brodul/scripts/auto_backup.sh"
  '';
  services.udev.path = with pkgs; [ coreutils bash];

  nix.maxJobs = lib.mkDefault 4;
}
