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
| `hosts/rpizero/configuration.nix` | Shared Pi Zero 2 W settings: browser, Syncthing, CUPS printing, user |
| `hosts/rpizero/default.nix` | Installed-system entry point (hardware + shared config) |
| `hosts/rpizero/sd-image.nix` | SD-image build entry point (`sd-image-aarch64` module + shared config) |
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

The Pi Zero 2 W is `aarch64` with only 512 MB of RAM — too weak to build itself —
so you build a flashable SD image on another machine (e.g. Vipera). The config is
split into three files so the same settings drive both an image build and an
on-device rebuild:

| File | Role |
|------|------|
| `configuration.nix` | Shared, hardware-agnostic settings (browser, Syncthing, CUPS, user) |
| `sd-image.nix` | Image build layer — imports the `sd-image-aarch64` module (root FS + bootloader) |
| `hardware-configuration.nix` | On-device hardware layout; placeholder — regenerate on the Pi |
| `default.nix` | Installed-system entry point = `hardware-configuration.nix` + `configuration.nix` |

**Cross-building the SD image (recommended: QEMU/binfmt emulation).**
True cross-compilation of a full NixOS closure tends to break, so instead let an
x86_64 host build the aarch64 derivations under emulation. Vipera already enables
this via `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`; on any other host,
add that line and `nixos-rebuild switch` once. Then:

```bash
nix build .#nixosConfigurations.rpizero-sd.config.system.build.sdImage
```

Flash the result:

```bash
zstd -d result/sd-image/*.img.zst -o rpizero.img
sudo dd if=rpizero.img of=/dev/sdX bs=4M conv=fsync status=progress
```

**Or, on the running Pi**, regenerate the hardware config and rebuild in place:

```bash
sudo nixos-generate-config   # refresh hosts/rpizero/hardware-configuration.nix
sudo nixos-rebuild switch --flake /etc/nixos#rpizero
```

Printing (CUPS) is reachable at <http://localhost:631>; the Syncthing GUI is at
<http://127.0.0.1:8384>. The bundled `gutenprint` drivers cover most OKI models —
add a vendor PPD to `services.printing.drivers` if your exact model needs one.

> **Firmware note:** this uses the mainline `sd-image-aarch64` module. If the
> generic image doesn't boot on the Pi Zero 2 W, add the
> [`nixos-hardware`](https://github.com/NixOS/nixos-hardware) Raspberry Pi module
> as a flake input and import it in `sd-image.nix`.

#### Building on Windows (VirtualBox / WSL2)

No Linux box? Build the image inside a Linux environment on Windows. This is
QEMU *user-mode* emulation (`binfmt`), not hardware virtualization, so it works
in a plain VM — nested VT-x is **not** required.

- **VirtualBox — NixOS guest (simplest):** install NixOS from the ISO, add
  `boot.binfmt.emulatedSystems = [ "aarch64-linux" ];` and the flakes feature to
  `/etc/nixos/configuration.nix`, `sudo nixos-rebuild switch`, then run the
  `nix build ...rpizero-sd...sdImage` command above.
- **VirtualBox — Ubuntu guest:** install Nix, then
  `sudo apt install qemu-user-static binfmt-support`, add
  `extra-platforms = aarch64-linux` to `/etc/nix/nix.conf`, restart the daemon,
  and build.
- **WSL2 (lighter than a full VM):** install Ubuntu via WSL2, install Nix, do the
  same `qemu-user-static` step, and build.

Give the environment room — the aarch64 build runs under emulation and is slow:
**60 GB+ disk, 8 GB+ RAM, as many cores as you can spare** (expect hours on the
first build). Copy `result/sd-image/*.img.zst` out to Windows and flash it with
**Raspberry Pi Imager** or **balenaEtcher**, which read `.zst`/`.img` directly —
no `dd` needed.

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
