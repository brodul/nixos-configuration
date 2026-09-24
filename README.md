# NixOS Configuration

Hosts: `vipera` (workstation, below) and `pbs` (Proxmox Backup Server VPS, see [PBS VPS](#pbs-vps)).

## Vipera

## Host Overview

- **Hostname:** Vipera
- **Purpose:** Primary workstation (development, gaming, media)
- **CPU:** AMD
- **Storage:** LUKS-encrypted root
- **User:** `brodul` (uid 1000)
- **Channel:** `nixos-unstable` (rolling)

---

## Flake Structure

| File | Purpose |
|------|---------|
| `flake.nix` | Flake inputs (nixpkgs unstable, home-manager, disko, deploy-rs, nixos-pbs), `mkHost` system outputs, deploy-rs nodes |
| `flake.lock` | Pinned input revisions — commit this for reproducible builds |
| `modules/common.nix` | Shared config applied to every machine: base CLI tools, sudo rules, ssh, gnupg |
| `modules/desktop.nix` | Graphical workstation stack: X11/i3/XFCE, pipewire, gaming, virtualization |
| `hosts/vipera/default.nix` | Machine-specific config for Vipera: hostname, boot, networking, user, home-manager |
| `hosts/vipera/hardware-configuration.nix` | Auto-generated hardware/disk/filesystem config (commit this) |
| `modules/loop-image.nix` | `services.loopImages`: create, format once, and loop-mount an image file (VPS without spare disks) |
| `hosts/pbs/default.nix` | VPS base: GRUB (BIOS+UEFI), SSH key-only root, firewall |
| `hosts/pbs/disk-config.nix` | disko partition layout used by nixos-anywhere |
| `hosts/pbs/pbs.nix` | PBS, S3 endpoint + datastore bootstrap, loop-mounted chunk cache |
| `users/brodul/home.nix` | Home Manager config for `brodul`: user packages, shell, dotfiles |
| `secrets/` | SOPS-encrypted secrets — **gitignored, never commit** |

---

## Key Services

| Service | Config |
|---------|--------|
| Desktop | i3 (WM) + XFCE (panel/session), LightDM display manager |
| Audio | Pipewire (ALSA + PulseAudio compat) |
| Network | NetworkManager, ZeroTier (network ID in `/etc/nixos-local/`) |
| Remote | OpenSSH server |
| Virtualization | Docker, VirtualBox |
| Gaming | Steam + Gamescope + GameMode |
| Bluetooth | blueman |
| Printing | CUPS + foo2zjs |
| Secrets | SOPS (installed via home.nix) |

---

## Applying Changes

```bash
sudo nixos-rebuild switch --flake /etc/nixos#vipera --impure
```

`--impure` is required because `hosts/vipera/default.nix` reads local secrets from `/etc/nixos-local/`
(outside the flake's git tree). After the initial rebuild, `brodul` can run this without a password.

## Updating Packages

```bash
cd /etc/nixos
nix flake update
sudo nixos-rebuild switch --flake /etc/nixos#vipera --impure
```

This pulls the latest nixpkgs-unstable and home-manager, updating all packages including `claude-code`.

---

## Secrets Management (SOPS)

- `sops` is installed via `home.nix`
- Encrypt secrets with `sops secrets/mysecret.yaml`
- The `secrets/` directory is **gitignored** — never commit plaintext secrets
- Future: add `.sops.yaml` with age/GPG key configuration

---

## Claude Code Sudo Delegation

`security.sudo.extraRules` in `modules/common.nix` grants `brodul` passwordless access to:

- `nixos-rebuild` — apply config changes
- `systemctl` — manage services
- `nix-store` — inspect/gc the Nix store

This allows Claude Code to apply NixOS changes autonomously during a session without interactive password prompts.

> **Note:** sudo resolves `/run/current-system/sw/bin/` symlinks to store paths.
> If passwordless sudo stops working after a rebuild, check the resolved path with
> `readlink -f /run/current-system/sw/bin/nixos-rebuild` and fall back to
> `security.sudo.extraConfig` with a raw sudoers string.

---

## PBS VPS

Proxmox Backup Server on a VPS, using the experimental
[AWildLeon/nixos-pbs](https://github.com/AWildLeon/nixos-pbs) module and overlay. The
datastore uses the S3 backend (a tech preview in PBS 4.x), with its local chunk cache on a loop-mounted
ext4 image at `/srv/pbs-cache` because the VPS has no spare disk.

### Before the first install

Fill in the `TODO`s:

- `flake.nix`: `deploy.nodes.pbs.hostname`
- `hosts/pbs/default.nix`: root SSH public key
- `hosts/pbs/disk-config.nix`: disk device (`/dev/sda` vs `/dev/vda`)
- `hosts/pbs/pbs.nix`: S3 endpoint, region, bucket, and cache size

### Install (nixos-anywhere + disko)

```bash
# S3 credentials go onto the target and never into the repo or the Nix store
tmp=$(mktemp -d)
install -d -m 700 "$tmp/var/lib/pbs-secrets"
printf 'PBS_S3_ACCESS_KEY=...\nPBS_S3_SECRET_KEY=...\n' > "$tmp/var/lib/pbs-secrets/s3.env"
chmod 600 "$tmp/var/lib/pbs-secrets/s3.env"

nix run github:nix-community/nixos-anywhere -- \
  --flake .#pbs \
  --generate-hardware-config nixos-generate-config ./hosts/pbs/hardware-configuration.nix \
  --extra-files "$tmp" \
  root@<vps-ip>
```

Commit the generated `hosts/pbs/hardware-configuration.nix` afterwards.

### Updates (deploy-rs)

```bash
nix run github:serokell/deploy-rs -- .#pbs
```

Magic rollback is on by default. If the new generation breaks SSH, it reverts on its own.

### How the pieces fit at boot

1. `loop-image-srv-pbs-cache.service` creates the sparse image and formats it once, before
   `srv-pbs\x2dcache.mount`. This can't be done with tmpfiles, which runs after `local-fs.target`.
2. The mount is `nofail`, so SSH stays up if it fails. The PBS units use
   `RequiresMountsFor`, so they never write into the bare directory on the root fs.
3. `pbs-s3-bootstrap.service` creates the S3 endpoint and the `main` datastore if they're missing
   and never updates them. It is skipped until `/var/lib/pbs-secrets/s3.env` exists.
4. The module's `proxmox-backup-setup.service` then reconciles the prune job. The build warns
   that `main` isn't in `ensureDatastores`; that's expected.

### Notes

- **Cache size**: set to 20G. Proxmox recommends 64–128G because the cache holds real chunk
  data. A smaller cache means more S3 round-trips.
- **Sparse image**: it can overcommit the root fs. Set `preallocate = true` or watch free space on `/`.
- **Web UI login** is `root@pam`, and root has no password. Set one (`passwd`) or create a PBS
  user with `proxmox-backup-manager user create`.
- **No verify job**: verifying an S3 datastore downloads every chunk, which costs egress.
