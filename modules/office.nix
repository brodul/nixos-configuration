{ pkgs, ... }:
{
  # Office-desktop layer for the Pi 4B: the plumbing a bare i3 session lacks
  # (audio, notifications, automount, bluetooth) plus the actual office apps and
  # document fonts. Autostarts (dunst, udiskie, blueman-applet) and the i3lock /
  # terminal / screenshot keybinds live in users/brodul/home-rpizero.nix.
  #
  # NOTE (aarch64): Teams/Slack/Zoom/OneDrive/MS-365 have no ARM-Linux desktop
  # builds — use their web versions in Firefox on this Pi.

  # Audio — PipeWire (essential for video calls). rtkit is enabled in common.nix.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Bluetooth — wireless headsets / mice.
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Removable media: automount + GVFS (so the file manager can mount USB sticks).
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Secret storage for GUI apps (keyring: WiFi/browser passwords).
  services.gnome.gnome-keyring.enable = true;

  # Scanning — SANE backend for simple-scan (pairs with the CUPS printer setup).
  hardware.sane.enable = true;

  # Document fonts so Word/Excel/PowerPoint files render with correct metrics.
  fonts.packages = with pkgs; [
    liberation_ttf          # metric-compatible with Arial / Times / Courier
    dejavu_fonts
    noto-fonts
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    # Office suite + documents
    libreoffice-fresh
    zathura                 # lightweight PDF viewer
    simple-scan             # document scanning

    # Everyday desktop apps
    pcmanfm                 # GUI file manager
    alacritty               # terminal emulator (replaces xterm)
    flameshot               # screenshots
    feh                     # image viewer
    file-roller             # archive manager (zip/tar/…)
    pavucontrol             # audio mixer / device picker
    rofi                    # app launcher (nicer than dmenu)

    # i3 session helpers
    dunst                   # notification daemon (bare i3 has none)
    libnotify               # notify-send + client libraries
    i3lock                  # screen locker
    udiskie                 # tray automount helper for removable drives
    blueman                 # bluetooth manager + tray applet
  ];
}
