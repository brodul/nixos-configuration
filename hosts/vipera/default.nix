{ pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "Vipera";
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
