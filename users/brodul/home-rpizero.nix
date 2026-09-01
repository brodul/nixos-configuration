{ pkgs, lib, config, ... }:

let
  # polybar must be built with i3 + pulseaudio support for the workspace and
  # volume modules (the default nixpkgs build omits them).
  polybarPkg = pkgs.polybar.override { i3Support = true; pulseSupport = true; };

  # Restart-safe polybar launcher: quit any running instance, then start the bar
  # named "main" from ~/.config/polybar/config.ini.
  launchPolybar = pkgs.writeShellScript "launch-polybar" ''
    ${polybarPkg}/bin/polybar-msg cmd quit >/dev/null 2>&1 || true
    ${polybarPkg}/bin/polybar main >/tmp/polybar-brodul.log 2>&1 &
  '';
in
{
  # Home Manager profile for the Raspberry Pi 4B. Kept lean (the full
  # workstation profile in users/brodul/home.nix pulls in hundreds of packages),
  # but the Pi 4B has enough RAM that this doesn't have to be as minimal as the
  # old Pi Zero 2 W profile.
  home.username = "brodul";
  home.homeDirectory = "/home/brodul";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    htop
    tmux
    tree
    file
    # Graphical network/WiFi management on the bare i3 session:
    #   nm-applet            -> tray icon: click to pick a WiFi network / connect
    #   nm-connection-editor -> full GTK editor for connections
    networkmanagerapplet
    # Video playback outside the browser. `mpv <youtube-url>` (yt-dlp resolves
    # the stream) is still a lighter path than a full browser tab, but note:
    # on the stock generic kernel there is NO V4L2 hardware decoder, so decode
    # is software here too. Keep clips to 720p H.264 for smooth playback.
    mpv
    yt-dlp
    # Flip the keyboard group (US <-> SI) from an i3 keybind; see the i3
    # keybindings below (Mod4+Space). Also usable directly: `xkb-switch` prints
    # the current layout, `xkb-switch -n` cycles to the next.
    xkb-switch
    # Nord desktop look + behaviour (launched from the i3 startup below):
    polybarPkg   # themed status bar (replaces the plain i3bar)
    picom        # compositor: rounded corners + subtle shadows
    hsetroot     # sets the Nord gradient wallpaper
    xautolock    # idle -> i3lock (keeps the panel powered; no HDMI blank)
  ];

  # Don't route settings through dconf. On this bare i3 session there is no
  # D-Bus session bus during home-manager's systemd activation, so the dconf
  # write fails with "The name is not activatable" and aborts the whole user
  # generation. GTK apps read ~/.config/gtk-3.0/settings.ini directly, so we
  # lose nothing by turning dconf management off here.
  dconf.enable = false;

  # GTK app theming (LibreOffice, pcmanfm, nm-connection-editor, …): Nord theme,
  # Papirus-Dark icons, Noto Sans UI font, dark-mode preference.
  gtk = {
    enable = true;
    theme = { name = "Nordic"; package = pkgs.nordic; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    font = { name = "Noto Sans"; size = 10; };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  # Bibata cursor everywhere (X + GTK).
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  # Config files for the tools launched from the i3 startup.
  xdg.configFile = {
    "polybar/config.ini".source = ./polybar-config.ini;
    "picom/picom.conf".text = ''
      # Light compositor for the Pi 4B. The glx backend is required for rounded
      # corners; shadows are subtle and there is NO blur / NO fade, so it stays
      # snappy on the Pi. If it ever feels laggy, delete this / remove picom from
      # the i3 startup and everything else (gaps, borders, theme) still applies.
      backend = "glx";
      vsync = true;

      corner-radius = 8;
      rounded-corners-exclude = [
        "window_type = 'dock'",
        "class_g = 'i3-frame'"
      ];

      shadow = true;
      shadow-radius = 12;
      shadow-opacity = 0.35;
      shadow-offset-x = -12;
      shadow-offset-y = -12;
      shadow-exclude = [
        "window_type = 'dock'",
        "window_type = 'desktop'",
        "class_g = 'i3-frame'"
      ];

      fading = false;
      detect-rounded-corners = true;
      detect-client-opacity = true;
      use-damage = true;
    '';
  };

  # Ship an i3 config so the first-boot i3-config-wizard never runs. The wizard
  # (and bare i3) render text with the X11 core "fixed" font, whose alias lives
  # in the font-alias package that is NOT in the X server FontPath on the SD
  # image -> the wizard shows up with blank text. Pinning a Pango/fontconfig
  # font (DejaVu Sans Mono) sidesteps that entirely, including for i3bar.
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4"; # use the Super/Meta key as the i3 modifier
      fonts = {
        names = [ "JetBrainsMono Nerd Font" ];
        size = 10.0;
      };
      # No i3bar — polybar replaces it (launched from `startup` below).
      bars = [ ];

      # A bit of breathing room + smart gaps/borders for the modern tiled look.
      gaps = {
        inner = 10;
        outer = 4;
        smartGaps = true;
        smartBorders = "on";
      };

      # Thin, title-less window borders (polybar shows window context instead).
      window = {
        titlebar = false;
        hideEdgeBorders = "smart";
      };

      # Nord window-border colours. Attrs: border / background / text /
      # indicator / childBorder.
      colors = {
        background = "#2E3440";
        focused = { border = "#88C0D0"; background = "#3B4252"; text = "#ECEFF4"; indicator = "#88C0D0"; childBorder = "#88C0D0"; };
        focusedInactive = { border = "#3B4252"; background = "#2E3440"; text = "#D8DEE9"; indicator = "#3B4252"; childBorder = "#3B4252"; };
        unfocused = { border = "#2E3440"; background = "#2E3440"; text = "#7B88A1"; indicator = "#2E3440"; childBorder = "#3B4252"; };
        urgent = { border = "#BF616A"; background = "#BF616A"; text = "#ECEFF4"; indicator = "#BF616A"; childBorder = "#BF616A"; };
      };

      # Autostart tray applets + desktop daemons each session.
      startup = [
        { command = "nm-applet"; notification = false; }         # WiFi/network tray
        { command = "blueman-applet"; notification = false; }    # bluetooth tray
        { command = "dunst"; notification = false; }             # notification daemon
        { command = "udiskie --tray"; notification = false; }    # USB automount tray
        # Nord gradient wallpaper (Polar Night -> a touch lighter, diagonal).
        { command = "${pkgs.hsetroot}/bin/hsetroot -add '#2E3440' -add '#434C5E' -gradient 40"; notification = false; }
        # Themed status bar + light compositor.
        { command = "${launchPolybar}"; notification = false; }
        { command = "${pkgs.picom}/bin/picom --config ${config.xdg.configHome}/picom/picom.conf -b"; notification = false; }
        # Auto screen-LOCK on idle. We drive it with xautolock (not the X
        # screensaver) because screen blanking/DPMS is disabled system-wide to
        # avoid the Pi's "no signal" HDMI drop (see modules/theme.nix). xautolock
        # runs i3lock after 10 min idle — the panel stays powered, just locked.
        # xss-lock additionally locks before suspend / on `loginctl lock-session`.
        { command = "${pkgs.xautolock}/bin/xautolock -time 10 -locker '${pkgs.i3lock}/bin/i3lock -n -c 2E3440'"; notification = false; }
        { command = "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${pkgs.i3lock}/bin/i3lock -n -c 2E3440"; notification = false; }
      ];

      # Office-desktop keybinds. These go through `keybindings` (not extraConfig)
      # so they MERGE with home-manager's generated defaults via mkOptionDefault:
      # Mod4+Return and Mod4+d override the stock i3-sensible-terminal / dmenu
      # binds in place, instead of appending a second `bindsym` for the same key
      # (two binds on one key made i3 pop a duplicate-binding nagbar). Print and
      # Mod4+Shift+x are new keys.
      #
      # Why not extraConfig: home-manager inlines "Mod4+" into the binds it
      # generates and never emits a `set $mod` line, so a `$mod` reference in
      # extraConfig expands to the empty string — `bindsym $mod+Return` silently
      # becomes `bindsym Return`, and bare keys start firing i3 actions.
      keybindings = lib.mkOptionDefault {
        "Mod4+Return" = "exec alacritty";               # terminal (replaces i3-sensible-terminal)
        "Mod4+d" = "exec rofi -show drun";              # launcher (replaces dmenu)
        "Mod4+Shift+x" = "exec ${pkgs.i3lock}/bin/i3lock -c 2E3440"; # lock screen
        "Print" = "exec flameshot gui";                 # region screenshot
        "Mod4+space" = "exec ${pkgs.xkb-switch}/bin/xkb-switch -n"; # cycle US <-> SI keyboard layout
      };
    };

    # Border width for the title-less windows above (the structured `window`
    # option can't set the pixel width). No `$mod` here, so extraConfig is safe.
    extraConfig = ''
      default_border pixel 2
      default_floating_border pixel 2
    '';
  };

  # Firefox, configured for the Pi 4.
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-esr;
    profiles.default = {
      id = 0;
      settings = {
        # Pi-4 rendering-glitch workaround. The V3D hardware WebRender + X11-EGL
        # path produces ghosting / stale-tile artifacts on the Pi 4; force
        # software WebRender instead. The desktop GPU (vc4/v3d) still composites
        # the session — only Firefox's own content rendering goes to software.
        # (Compositing is independent of video *decode*, below.)
        "gfx.webrender.software" = true;
        "gfx.x11-egl.force-disabled" = true;
        "layers.acceleration.disabled" = true;

        # Hardware video decode prefs — INERT on this setup, kept only as a
        # harmless marker. Two independent reasons there is no HW decode:
        #   1. The stock generic sd-image kernel has no V4L2 decoder nodes
        #      (bcm2835-codec / rpivid live only in the downstream RPi kernel,
        #      which we deliberately don't build — see configuration.nix).
        #   2. nixpkgs firefox-esr isn't compiled with --enable-v4l2 anyway
        #      (libxul.so has zero v4l2 symbols), so even with those nodes it
        #      couldn't use them.
        # In-browser video therefore stays on CPU; hold YouTube to 720p H.264
        # via enhanced-h264ify (below).
        "media.hardware-video-decoding.force-enabled" = true;
        "media.ffmpeg.vaapi.enabled" = true;
      };
    };
    # Force-install enhanced-h264ify: makes YouTube serve H.264 instead of
    # VP9/AV1. H.264 is far cheaper for the Pi 4 to decode in software, which is
    # the only decode path available here (no HW decoder on the stock kernel).
    policies.ExtensionSettings = {
      "{9a41dee2-b924-4161-a971-7fb35c053a4a}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhanced-h264ify/latest.xpi";
        installation_mode = "force_installed";
      };
    };
  };

  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      theme = "clean";
      plugins = [ "git" "tmux" ];
    };
  };

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfreePredicate = (_: true);
}
