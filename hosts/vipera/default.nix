{ pkgs, inputs, ... }:
let
  splashPkg = inputs.deep-auth.packages.${pkgs.system}.default;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "Vipera";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Ljubljana";

  networking.modemmanager.enable = false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.systemd.storePaths = [ splashPkg pkgs.ncurses ];

  boot.initrd.systemd.targets.cryptsetup = {
    wants = [ "cryptsetup-pre.target" ];
  };

  boot.initrd.systemd.services.deep-auth = {
    description = "Deep auth splash";
    wantedBy = [ "cryptsetup-pre.target" ];
    before = [ "cryptsetup-pre.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${splashPkg}/bin/splash";
      TimeoutStartSec = 600;
      StandardInput = "tty";
      StandardOutput = "tty";
      TTYPath = "/dev/console";
      TTYReset = true;
      TTYVTDisallocate = true;
      Environment = [
        "TERM=linux"
        "TERMINFO=${pkgs.ncurses}/share/terminfo"
      ];
    };
  };

  services.zerotierone = {
    enable = true;
    joinNetworks = import /etc/nixos-local/zerotier.nix;
  };

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 4646 8080 ];
  networking.firewall.trustedInterfaces = [ "bridge0" "lo" ];

  users.users.brodul = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "sudo" "audio" "video" "scanner"
                    "tty" "lp" "dialout" "networkmanager"
                    "docker" "vboxusers" "wireshark" ];
    shell = pkgs.zsh;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.brodul = import ../../users/brodul/home.nix;
  };

  system.stateVersion = "23.11";
}
