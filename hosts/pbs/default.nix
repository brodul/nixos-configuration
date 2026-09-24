{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./pbs.nix
    ../../modules/common.nix
    ../../modules/loop-image.nix
  ];

  networking.hostName = "pbs";
  networking.firewall.enable = true;

  time.timeZone = "Europe/Ljubljana";

  # GRUB covers both BIOS and UEFI VPSes (see disk-config.nix).
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # nixos-anywhere and deploy-rs both connect as root with a key.
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
  };
  users.users.root.openssh.authorizedKeys.keys = [
    # TODO: "ssh-ed25519 AAAA... brodul"
  ];

  system.stateVersion = "26.05";
}
