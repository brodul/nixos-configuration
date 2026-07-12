{ pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
  ];

  networking.hostName = "rpizero";
  networking.networkmanager.enable = true;
  networking.modemmanager.enable = false;

  time.timeZone = "Europe/Ljubljana";

  # Lightweight graphical session. The Pi Zero 2 W only has 512 MB of RAM, so
  # we deliberately skip the heavy workstation stack in modules/desktop.nix
  # (Steam, VirtualBox, Docker, XFCE) and run a bare i3 session instead.
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    windowManager.i3.enable = true;
    displayManager.lightdm.enable = true;
  };

  # Browser + minimal i3 helpers.
  environment.systemPackages = with pkgs; [
    firefox-esr
    i3status
    dmenu
  ];

  # Printing: CUPS with Gutenprint, which provides drivers for a wide range of
  # OKI laser/LED printers. Adjust `drivers` if your specific OKI model needs a
  # vendor PPD.
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint gutenprintBin ];
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

  # Compressed RAM swap — important headroom on a 512 MB machine.
  zramSwap.enable = true;

  users.users.brodul = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "sudo" "audio" "video" "tty" "lp" "networkmanager" ];
    shell = pkgs.zsh;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.brodul = import ../../users/brodul/home-rpizero.nix;
  };

  system.stateVersion = "23.11";
}
