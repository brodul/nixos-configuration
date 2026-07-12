{ pkgs, ... }:

{
  # Minimal Home Manager profile for the Raspberry Pi Zero 2 W. The full
  # workstation profile (users/brodul/home.nix) pulls in hundreds of packages
  # that would be far too heavy for a 512 MB SD-card machine.
  home.username = "brodul";
  home.homeDirectory = "/home/brodul";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    htop
    tmux
    tree
    file
  ];

  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      theme = "clean";
      plugins = [ "git" "tmux" ];
    };
  };

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfreePredicate = (_: true);
}
