# Filesystems backed by an image file on the root fs, loop-mounted.
# For VPSes without a spare disk or partition.
#
# systemd-tmpfiles runs after local-fs.target, too late to create the image
# before its mount, so a oneshot ordered before the mount unit does it instead.
{ config, lib, pkgs, utils, ... }:
let
  cfg = config.services.loopImages;

  # Plain name (no \x2d escapes) so it is easy to type in systemctl.
  unitName = mountPoint: "loop-image-${lib.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" mountPoint)}";
in
{
  options.services.loopImages = lib.mkOption {
    default = { };
    description = "Image files to create, format once, and loop-mount, keyed by mount point.";
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        image = lib.mkOption {
          type = lib.types.str;
          example = "/var/lib/images/cache.img";
          description = "Path of the backing image file.";
        };
        size = lib.mkOption {
          type = lib.types.str;
          example = "64G";
          description = "Size of the image when first created (only applied at creation).";
        };
        preallocate = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Reserve the blocks up front with fallocate. A sparse image can
            overcommit: if the root fs fills up, writes inside the image fail
            even though it looks like it has free space.
          '';
        };
        label = lib.mkOption {
          type = lib.types.str;
          default = "loopimage";
          description = "ext4 filesystem label.";
        };
      };
    });
  };

  config = lib.mkIf (cfg != { }) {
    systemd.services = lib.mapAttrs' (mountPoint: img:
      lib.nameValuePair (unitName mountPoint) {
        description = "Create and format loop image for ${mountPoint}";
        unitConfig = {
          DefaultDependencies = false;
          RequiresMountsFor = [ (builtins.dirOf img.image) ];
        };
        before = [ "${utils.escapeSystemdPath mountPoint}.mount" ];
        path = [ pkgs.coreutils pkgs.util-linux pkgs.e2fsprogs ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          img=${lib.escapeShellArg img.image}
          mkdir -p "$(dirname "$img")"
          if [ ! -e "$img" ]; then
            ${if img.preallocate
              then ''fallocate -l ${lib.escapeShellArg img.size} "$img"''
              else ''truncate -s ${lib.escapeShellArg img.size} "$img"''}
          fi
          # Format only once: never touch an image that already has a filesystem.
          if ! blkid "$img" >/dev/null 2>&1; then
            mkfs.ext4 -q -m 0 -L ${lib.escapeShellArg img.label} "$img"
          fi
        '';
      }) cfg;

    fileSystems = lib.mapAttrs (mountPoint: img: {
      device = img.image;
      fsType = "ext4";
      options = [
        "loop"
        # Keep the box reachable over SSH if the mount fails; consumers should
        # use RequiresMountsFor so they don't write into the bare directory.
        "nofail"
        "x-systemd.requires=${unitName mountPoint}.service"
      ];
    }) cfg;
  };
}
