{ pkgs, ... }:
{
  # Visual theming for the Pi 4B office desktop: a coherent Nord look across the
  # login screen, GTK apps, i3, the bar and the compositor. The per-user pieces
  # (GTK theme, polybar, picom, i3 colours/gaps) live in
  # users/brodul/home-rpizero.nix; this module holds the SYSTEM-level parts:
  # the no-blank Xorg fix, the fonts/theme assets, and the lightdm greeter.

  # ── No screen blanking / DPMS ────────────────────────────────────────────────
  # On the Pi 4 (vc4 KMS) an X DPMS power-off actually cuts the HDMI signal, and
  # many monitors then refuse to re-sync — the display just shows "no signal"
  # until X is poked. So we disable X's blank/standby/suspend/off timers
  # entirely, for the greeter AND every user session. The screen is still LOCKED
  # on idle (xautolock + i3lock, see home-rpizero.nix), which keeps the panel
  # powered and only draws the lock screen — no HDMI drop.
  services.xserver.serverFlagsSection = ''
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
  '';
  # Belt-and-suspenders: the ServerFlags above disable the *screensaver* blank
  # but the vc4 driver kept honouring the DPMS timers, so also run `xset` when X
  # starts. lightdm keeps the same X server from greeter through to the user
  # session, so this one hook disables blanking/DPMS for both.
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xset}/bin/xset s off
    ${pkgs.xorg.xset}/bin/xset -dpms
    ${pkgs.xorg.xset}/bin/xset s noblank
  '';

  # ── Theme assets ─────────────────────────────────────────────────────────────
  # Installed system-wide (not just in brodul's home) so the lightdm greeter,
  # which runs as the `lightdm` user, can find the theme/icons/cursor too.
  environment.systemPackages = with pkgs; [
    nordic              # Nord GTK + window theme
    papirus-icon-theme  # icon set (Papirus-Dark)
    bibata-cursors      # cursor theme (Bibata-Modern-Ice)
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono  # UI/bar font with programming + icon glyphs
  ];

  # ── Themed login screen ──────────────────────────────────────────────────────
  # lightdm's GTK greeter, dressed in the same Nord palette on a Polar-Night
  # background so the machine looks styled from boot.
  services.xserver.displayManager.lightdm.greeters.gtk = {
    enable = true;
    theme = { name = "Nordic"; package = pkgs.nordic; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    cursorTheme = { name = "Bibata-Modern-Ice"; package = pkgs.bibata-cursors; size = 24; };
    extraConfig = ''
      background = #2E3440
      font-name = Noto Sans 11
    '';
  };
}
