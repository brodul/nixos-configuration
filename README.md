# NixOS Configuration — brodul machines

## Hosts

### Vipera

- **Hostname:** Vipera
- **Purpose:** Primary workstation (development, gaming, media)
- **CPU:** AMD (`x86_64-linux`)
- **Storage:** LUKS-encrypted root
- **User:** `brodul` (uid 1000)
- **Channel:** `nixos-unstable` (rolling)

### rpizero

- **Hostname:** rpizero
- **Purpose:** Lightweight always-on box — web browsing, file syncing, print server
- **Hardware:** Raspberry Pi Zero 2 W (`aarch64-linux`, 512 MB RAM)
- **User:** `brodul` (uid 1000)
- **Notes:** Runs a bare i3 session (no XFCE/gaming/virtualization stack) plus
  `zram` swap to cope with 512 MB of RAM. Shares `modules/common.nix` with
  Vipera but has its own minimal Home Manager profile
  (`users/brodul/home-rpizero.nix`).

---

## Flake Structure

| File | Purpose |
|------|---------|
| `flake.nix` | Flake inputs (nixpkgs unstable, home-manager) and `mkHost` system outputs |
| `flake.lock` | Pinned input revisions — commit this for reproducible builds |
| `modules/common.nix` | Shared config applied to every machine: base CLI tools, sudo rules, ssh, gnupg |
| `modules/desktop.nix` | Graphical workstation stack: X11/i3/XFCE, pipewire, gaming, virtualization |
| `hosts/vipera/default.nix` | Machine-specific config for Vipera: hostname, boot, networking, user, home-manager |
| `hosts/vipera/hardware-configuration.nix` | Auto-generated hardware/disk/filesystem config (commit this) |
| `hosts/rpizero/default.nix` | Machine-specific config for the Pi Zero 2 W: browser, Syncthing, CUPS printing |
| `hosts/rpizero/hardware-configuration.nix` | Placeholder aarch64/extlinux hardware config — regenerate on-device |
| `users/brodul/home.nix` | Home Manager config for `brodul`: user packages, shell, dotfiles |
| `users/brodul/home-rpizero.nix` | Minimal Home Manager profile used by the Pi Zero 2 W |
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

### Vipera

```bash
sudo nixos-rebuild switch --flake /etc/nixos#vipera --impure
```

`--impure` is required because `hosts/vipera/default.nix` reads local secrets from `/etc/nixos-local/`
(outside the flake's git tree). After the initial rebuild, `brodul` can run this without a password.

### rpizero (Raspberry Pi Zero 2 W)

The `hosts/rpizero/hardware-configuration.nix` in this repo is a placeholder —
building for real ARM hardware needs an actual filesystem/bootloader layout.
Two common paths:

**Build a bootable SD image** (typically on an `aarch64` builder or with binfmt
emulation, since the Pi Zero 2 W is too small to build for itself):

```bash
nix build .#nixosConfigurations.rpizero.config.system.build.sdImage
```

**Or, on the running Pi**, regenerate the hardware config and rebuild in place:

```bash
sudo nixos-generate-config   # refresh hosts/rpizero/hardware-configuration.nix
sudo nixos-rebuild switch --flake /etc/nixos#rpizero
```

Printing (CUPS) is reachable at <http://localhost:631>; the Syncthing GUI is at
<http://127.0.0.1:8384>. The bundled `gutenprint` drivers cover most OKI models —
add a vendor PPD to `services.printing.drivers` if your exact model needs one.

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
