# Proxmox Backup Server with an S3-backed datastore.
#
# The chunk data lives in an S3-compatible bucket; PBS keeps a local cache of
# chunks on a loop-mounted image (VPS: no spare disk). The S3 endpoint and the
# datastore are created by pbs-s3-bootstrap below, not by the module's
# ensureDatastores: its reconciler re-passes every flag on `datastore update`,
# and the S3 backend can only be set at creation.
{ config, lib, pkgs, inputs, ... }:
let
  pbsCfg = config.services.proxmox-backup-server;
  manager = "${pbsCfg.package}/bin/proxmox-backup-manager";

  cacheMount = "/srv/pbs-cache";

  s3 = {
    endpointId = "s3";
    endpoint = "s3.example.com"; # TODO: provider endpoint, may template {{bucket}}/{{region}}
    region = "us-east-1"; # TODO
    pathStyle = true; # most non-AWS providers want path-style
    bucket = "pbs-backups"; # TODO
  };

  datastore = "main";

  # Access keys stay out of the Nix store. Seed this file at install time with
  # `nixos-anywhere --extra-files` (see README), or copy it over by hand:
  #   PBS_S3_ACCESS_KEY=...
  #   PBS_S3_SECRET_KEY=...
  credentialsFile = "/var/lib/pbs-secrets/s3.env";
in
{
  nixpkgs.overlays = [ inputs.pbs.overlays.default ];

  # Prebuilt PBS from the upstream flake's own nixpkgs pin, so it comes from
  # Cachix instead of being compiled from source on every deploy.
  nix.settings = {
    substituters = [ "https://awildleon-nixos-pbs.cachix.org" ];
    trusted-public-keys = [
      "awildleon-nixos-pbs.cachix.org-1:4kEEBSONGJ0F7Ita/3ZRcTWaR6M7YHXhltJaoEYl3ew="
    ];
  };

  services.proxmox-backup-server = {
    enable = true;
    package = inputs.pbs.packages.${pkgs.stdenv.hostPlatform.system}.proxmox-backup-server-fhs;
    openFirewall = true;

    # Verify jobs are left out on purpose: verifying an S3 datastore downloads
    # every chunk, which costs egress.
    ensurePruneJobs."${datastore}-prune" = {
      inherit datastore;
      schedule = "daily";
      settings = {
        keep-daily = 7;
        keep-weekly = 4;
        keep-monthly = 6;
      };
    };
  };

  # Local chunk cache. Proxmox recommends 64–128G for the S3 cache because it
  # holds real chunk data, not just metadata; a smaller one means more S3
  # round-trips. Make sure the root fs has room (see `preallocate`).
  services.loopImages.${cacheMount} = {
    image = "/var/lib/images/pbs-cache.img";
    size = "20G";
    label = "pbs-cache";
  };

  # PBS must not start and write into the bare mount point on the root fs.
  systemd.services.proxmox-backup.unitConfig.RequiresMountsFor = [ cacheMount ];
  systemd.services.proxmox-backup-proxy.unitConfig.RequiresMountsFor = [ cacheMount ];

  # Idempotent: creates the S3 endpoint and datastore only if missing, and never
  # updates them (change them with proxmox-backup-manager / the UI afterwards).
  systemd.services.pbs-s3-bootstrap = {
    description = "Create PBS S3 endpoint and datastore";
    wantedBy = [ "multi-user.target" ];
    after = [ "proxmox-backup.service" "network-online.target" ];
    requires = [ "proxmox-backup.service" ];
    wants = [ "network-online.target" ];
    unitConfig = {
      RequiresMountsFor = [ cacheMount ];
      ConditionPathExists = credentialsFile;
    };
    path = [ pkgs.jq ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = credentialsFile;
    };
    # Flag names match PBS 4.x; check `proxmox-backup-manager s3 endpoint create --help`
    # after the first deploy.
    script = ''
      if ! ${manager} s3 endpoint list --output-format json \
          | jq -e --arg id ${lib.escapeShellArg s3.endpointId} 'any(.[]; .id == $id)' >/dev/null; then
        echo "creating S3 endpoint ${s3.endpointId}"
        ${manager} s3 endpoint create ${lib.escapeShellArg s3.endpointId} \
          --endpoint ${lib.escapeShellArg s3.endpoint} \
          --region ${lib.escapeShellArg s3.region} \
          --path-style ${lib.boolToString s3.pathStyle} \
          --access-key "$PBS_S3_ACCESS_KEY" \
          --secret-key "$PBS_S3_SECRET_KEY"
      fi

      if ! ${manager} datastore list --output-format json \
          | jq -e --arg n ${lib.escapeShellArg datastore} 'any(.[]; .name == $n)' >/dev/null; then
        echo "creating datastore ${datastore}"
        ${manager} datastore create ${lib.escapeShellArg datastore} \
          ${lib.escapeShellArg "${cacheMount}/${datastore}"} \
          --backend ${lib.escapeShellArg "type=s3,client=${s3.endpointId},bucket=${s3.bucket}"} \
          --gc-schedule daily
      fi
    '';
  };

  # The prune job needs the datastore to exist first.
  systemd.services.proxmox-backup-setup = {
    after = [ "pbs-s3-bootstrap.service" ];
    wants = [ "pbs-s3-bootstrap.service" ];
  };
}
