{ pkgs, ... }:
{
  services = {
    # Enable the X11 windowing system.
    xserver = {
      xkb.layout = "us";
      xkb.variant = "";
      enable = true;
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          i3status
          dmenu
        ];
      };
      desktopManager = {
        xterm.enable = false;
        xfce = {
          enable = true;
          noDesktop = true;
          enableXfwm = false;
        };
      };
      displayManager = {
        lightdm.enable = true;

      };
    };

    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };

    blueman.enable = true;

    # Enable CUPS to print documents.
    printing.enable = true;
    printing.drivers = [ pkgs.foo2zjs ];

    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
  };

  hardware.bluetooth.enable = true;

  fonts.packages = [ pkgs.fira-code ];

  # Gaming
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;

  # Virtualization
  virtualisation = {
    docker.enable = true;
    virtualbox.host.enable = true;
  };

  environment.systemPackages = with pkgs; [
    acpitool
    cpio
    mc
    pavucontrol
    borgbackup
    freecad
    direnv
    chromium
  ];
}
