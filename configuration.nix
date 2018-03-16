# Edit this configuration file to define what should be installed on
# the system.  Help is available in the configuration.nix(5) man page
# or the NixOS manual available on virtual console 8 (Alt+F8).

{ config, pkgs, lib, ... }:

{

  imports = [
  <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  # Users and groups
  users.users.brodul =
  {
    uid = 1000;
    isNormalUser = true;
    extraGroups=[
    "docker" "tty" "vboxusers" "networkmanager"
    "wheel" "dialout" "scanner" "lp" "audio"];
    shell = "/run/current-system/sw/bin/zsh";
  };

  programs.wireshark.enable= true;

  nix.trustedUsers = [ "root" "brodul"];

  # Virtualization

  virtualisation.virtualbox.host.enable = true;
  virtualisation.docker.enable = true;

  # Video

  hardware.opengl.enable = true;
  services.xserver.deviceSection = ''
  Option "TearFree" "true"
  '';
  services.xserver.useGlamor = true;

  # Sound
  /*hardware.pulseaudio = {
  enable = true;
  support32Bit = true;
  };*/
  sound.extraConfig = ''
  '';

  ###
  # Boot
  ###

  # Kernel modules

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];

  boot.kernelModules = [ "kvm-intel" "fuse" ];


  hardware.bluetooth.enable = true;

  # Timezone
  time.timeZone = "Europe/Ljubljana";

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.enableCryptodisk = true;
  boot.blacklistedKernelModules = [ "pcspkr" "snd_soc_skl" ];

  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda";

  boot.cleanTmpDir = true;
  boot.tmpOnTmpfs = true;

  boot.initrd.preLVMCommands = ''
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

  boot.initrd.luks.devices = [ {device =
    "/dev/mapper/all-crypted";
    name = "cryptedroot" ; preLVM=false;} ];
    fileSystems."/".device = "/dev/mapper/cryptedroot";
    fileSystems."/boot".device = "/dev/disk/by-label/boot";

    boot.extraModprobeConfig = ''
    options snd slots=snd-hda-intel
    '';

    ###
    # Services
    ###

    # List services that you want to enable:

    services.nixosManual.showManual = true;
    services.xserver.synaptics.enable = true;

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    services.printing.enable = true;
    services.printing.drivers = [ pkgs.foomatic_filters pkgs.foo2zjs ];

    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.layout = "us";
    # services.xserver.xkbOptions = "eurosign:e";

    # Enable the KDE Desktop Environment.
    # services.xserver.displayManager.kdm.enable = true;
    # services.xserver.desktopManager.kde4.enable = true;
    services.xserver.displayManager.lightdm.enable = true;
    services.xserver.desktopManager.xfce.enable = true;
    services.xserver.windowManager.i3.enable = true;
    #  services.xserver.displayManager.desktopManagerHandlesLidAndPower = true;

    services.elasticsearch.enable = true;
    services.mongodb.enable = true;

    ###
    # Networking
    ###

    boot.kernel.sysctl = {"net.ipv4.ip_forward" = 1;};
    hardware.enableRedistributableFirmware = true;
    networking.hostName = "blackhole";
    networking.networkmanager.enable = true;
    networking.firewall.enable = false; #TODO



    ###
    # Fonts
    ###

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
        enablePepperFlash = false;
        enablePepperPDF = true;
        jre = false;
      };

    };

    environment.systemPackages = with pkgs; [
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
    rabbitmq_server
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
    dmenu
    rxvt_unicode
    i3status
    i3lock
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
    gimp_2_8
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
    openra
    #xonotic

    # postgresql
    pgadmin

    # development
    nodePackages.jshint

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

    system.activationScripts.bin_lib_links = ''
    mkdir -p /usr/lib
    ln -fs ${pkgs.xlibs.libX11}/lib/libX11.so.6 /usr/lib/libX11.so.6
    '';


    services.udev.extraRules = ''
    # digispark
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16d0", ATTRS{idProduct}=="0753", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16d0", ATTRS{idProduct}=="0753", MODE:="0666", ENV{ID_MM_DEVICE_IGNORE}="1"

    # backup usb
    # ACTION=="add", SUBSYSTEM=="usb_device", ATTRS{idVendor}=="05dc", ATTRS{idProduct}=="a838", RUN+="bash /home/brodul/scripts/auto_backup.sh"
    '';
    services.udev.path = with pkgs; [ coreutils bash];

    nix.maxJobs = lib.mkDefault 4;
  }
