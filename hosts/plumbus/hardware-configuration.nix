# Placeholder until install. Regenerate with nixos-anywhere:
#   --generate-hardware-config nixos-generate-config ./hosts/plumbus/hardware-configuration.nix
# Filesystems come from disk-config.nix (disko), so none are declared here.
{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
