# Partition layout applied by nixos-anywhere (via disko) at install time.
# Hybrid BIOS + UEFI so it boots on either kind of VPS firmware.
{ ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda"; # TODO: check with `lsblk` in the rescue system (often /dev/vda)
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # BIOS boot partition for GRUB
        };
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
