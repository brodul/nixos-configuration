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
| `flake.nix` | Flake inputs (nixpkgs unstable, home-manager) and system output |
| `flake.lock` | Pinned input revisions — commit this for reproducible builds |
| `configuration.nix` | System-wide NixOS config: services, hardware, users, sudo rules |
| `hardware-configuration.nix` | Auto-generated hardware/disk/filesystem config (commit this) |
| `home.nix` | Home Manager config for `brodul`: user packages, shell, dotfiles |
| `main-user.nix` | NixOS module stub for user creation (currently unused) |
| `secrets/` | SOPS-encrypted secrets — **gitignored, never commit** |

---

## Key Services

| Service | Config |
|---------|--------|
| Desktop | i3 (WM) + XFCE (panel/session), LightDM display manager |
| Audio | Pipewire (ALSA + PulseAudio compat) |
| Network | NetworkManager, ZeroTier (network `56374ac9a4010bda`) |
| Remote | OpenSSH server |
| Virtualization | Docker, VirtualBox |
| Gaming | Steam + Gamescope + GameMode |
| Bluetooth | blueman |
| Printing | CUPS + foo2zjs |
| Secrets | SOPS (installed via home.nix) |

---

## Applying Changes

```bash
sudo nixos-rebuild switch --flake /etc/nixos#default --impure
```

`--impure` is required because `configuration.nix` reads local secrets from `/etc/nixos-local/`
(outside the flake's git tree). After the initial rebuild, `brodul` can run this without a password.

## Updating Packages

```bash
cd /etc/nixos
nix flake update
sudo nixos-rebuild switch --flake /etc/nixos#default --impure
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

`security.sudo.extraRules` in `configuration.nix` grants `brodul` passwordless access to:

- `nixos-rebuild` — apply config changes
- `systemctl` — manage services
- `nix-store` — inspect/gc the Nix store

This allows Claude Code to apply NixOS changes autonomously during a session without interactive password prompts.

> **Note:** sudo resolves `/run/current-system/sw/bin/` symlinks to store paths.
> If passwordless sudo stops working after a rebuild, check the resolved path with
> `readlink -f /run/current-system/sw/bin/nixos-rebuild` and fall back to
> `security.sudo.extraConfig` with a raw sudoers string.
