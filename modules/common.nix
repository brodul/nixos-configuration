{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    vim
    wget
    rsync
    git
    openssl
    zip
    curl
    nmap
    python3
    zsh
    patchelf
  ];

  # rtkit is optional but recommended
  security.rtkit.enable = true;
  security.polkit.enable = true;

  security.sudo.extraRules = [
    {
      users = [ "brodul" ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl";    options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix-store";    options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.zsh.enable = true;

  services.openssh.enable = true;

  # pinentry service
  services.pcscd.enable = true;
}
