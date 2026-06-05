{ lib, config, pkgs, ... }:

let
  cfg = config.main-user;
in
{
  options.main-user = {
    enable 
      = lib.mkEnableOption "enable user module";

    userName = lib.mkOption {
      default = "mainuser";
      description = ''
        username
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      isNormalUser = true;
      description = "main user";
      uid = 1000;
      extraGroups = [ "wheel" "sudo"
                      "audio" "video" "scanner"
                      "tty" "lp" "dialout"
                      "networkmanager"
                      "docker" "vboxusers" "wireshark"
      ];
      shell = pkgs.zsh;
    };
  };
}
