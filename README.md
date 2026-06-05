# NixOS Configuration — Vipera

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
| `flake.nix` | Flake inputs (nixpkgs unstable, home-manager) and `mkHost` system outputs |
| `flake.lock` | Pinned input revisions — commit this for reproducible builds |
| `modules/common.nix` | Shared config applied to every machine: base CLI tools, sudo rules, ssh, gnupg |
| `modules/desktop.nix` | Graphical workstation stack: X11/i3/XFCE, pipewire, gaming, virtualization |
| `hosts/vipera/default.nix` | Machine-specific config for Vipera: hostname, boot, networking, user, home-manager |
| `hosts/vipera/hardware-configuration.nix` | Auto-generated hardware/disk/filesystem config (commit this) |
| `users/brodul/home.nix` | Home Manager config for `brodul`: user packages, shell, dotfiles |
| `secrets/` | SOPS-encrypted secrets — **gitignored, never commit** |

---

## Key Services

| Service | Config |
|---------|--------|
| Desktop | i3 (WM) + XFCE (panel/session), LightDM display manager |
| Audio | Pipewire (ALSA + PulseAudio compat) |
| Network | NetworkManager, ZeroTier (network `REDACTED`) |
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
