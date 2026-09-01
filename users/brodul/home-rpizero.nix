{ pkgs, lib, ... }:

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
  ];

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
        names = [ "DejaVu Sans Mono" ];
        size = 11.0;
      };
      bars = [{
        statusCommand = "${pkgs.i3status}/bin/i3status";
        # Show the system tray on i3bar so nm-applet's WiFi icon appears.
        trayOutput = "primary";
        fonts = {
          names = [ "DejaVu Sans Mono" ];
          size = 11.0;
        };
      }];
      # Autostart tray applets + desktop daemons each session.
      startup = [
        { command = "nm-applet"; notification = false; }         # WiFi/network tray
        { command = "blueman-applet"; notification = false; }    # bluetooth tray
        { command = "dunst"; notification = false; }             # notification daemon
        { command = "udiskie --tray"; notification = false; }    # USB automount tray
        # Auto screen-lock. `xset s 600 5` arms the X screensaver at 10 min idle;
        # xss-lock catches that (and logind lock/suspend signals) and runs i3lock,
        # so the screen locks on idle AND before sleep. -n keeps i3lock in the
        # foreground so xss-lock knows when the lock clears. Mod4+Shift+x still
        # locks on demand (see keybindings below).
        { command = "xset s 600 5"; notification = false; }
        { command = "xss-lock --transfer-sleep-lock -- i3lock -n -c 000000"; notification = false; }
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
        "Mod4+Return" = "exec alacritty";         # terminal (replaces i3-sensible-terminal)
        "Mod4+d" = "exec rofi -show drun";        # launcher (replaces dmenu)
        "Mod4+Shift+x" = "exec i3lock -c 000000"; # lock screen
        "Print" = "exec flameshot gui";           # region screenshot
      };
    };
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
