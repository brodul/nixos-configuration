{ pkgs, ... }:

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
      # Autostart the NetworkManager applet into the tray each session.
      startup = [
        { command = "${pkgs.networkmanagerapplet}/bin/nm-applet"; notification = false; }
      ];
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
