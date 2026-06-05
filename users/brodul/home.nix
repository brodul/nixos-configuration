{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "brodul";
  home.homeDirectory = "/home/brodul";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    awscli
    btop
    claude-code
    flameshot
    nomad
    terraform
    dig
    dive
    # move solaar to sysyem
    solaar
    discord
    elinks
    elixir
    evince
    espeak
    ffmpeg
    file
    # freecad
    fzf
    gh
    gitleaks
    go
    google-cloud-sdk
    # assume
    granted
    graphviz
    groovy
    helm
    htop
    httpie
    iftop
    inkscape
    inotify-tools
    iotop
    ipcalc
    jq
    jsonnet
    k6
    k9s
    kind
    kopia
    kubectl
    kubectx
    kubie
    kicad
    libnotify
    librecad
    libreoffice
    libxml2
    lnav
    lynis
    mc
    mimic
    mplayer
    mtr
    netcat
    nethogs
    niv
    nixpkgs-fmt
    nodejs
    # openscad
    packer
    pandoc
    parallel
    pdftk
    poetry
    popeye
    portfolio
    postgresql
    protobuf
    # proxsign
    pssh
    # pycharm-community-bin
    python3
    pulsemixer
    qbittorrent
    rclone
    restic
    ruby
    rustup
    salt
    shellcheck
    shutter
    slack
    sops
    syncthing
    # synergy
    tanka
    thunderbird-bin
    tig
    tmux
    tree
    vlc
    # vagrant
    vault
    vscode
    websocat
    # winbox
    # wireshark-qt-4.0.10
    xclip
    xournalpp
    yarn
    yq
    zoom-us
    zip unzip
    zbar

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # xsession.windowManager.i3 = {
  #   enable = true;
  #   config.fonts = {
  #     names = [ "DejaVu Sans Mono" "FontAwesome5Free" ];
  #     style = "Bold Semi-Condensed";
  #     size = 12.0;
  #   };
  #   config.bars = [
  #     {fonts = {
  #     names = [ "DejaVu Sans Mono" "FontAwesome5Free" ];
  #     style = "Bold Semi-Condensed";
  #     size = 12.0;
  #   };}
  #   ];
    
  # };

  programs.zsh = {
    enable = true;
    autocd = true;
    # dotDir = ".config/zsh";
    autosuggestion.enable = true;
    enableCompletion = true;
    shellAliases = {
      # sl = "exa";
      # ls = "exa";
      # l = "exa -l";
      # la = "exa -la";
      ip = "ip --color=auto";
    };
    oh-my-zsh = {
      enable = true;
      theme = "clean";
      plugins = [ "direnv" "docker" "fzf" "gh" "git" "kubectl" "tmux" ];
    };
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };


  # programs.tmux = {
  #   enable = true;
  # };
  # programs.i3status = {
  #   enable = true;
  # };
  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/brodul/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfreePredicate = (_: true);
}
