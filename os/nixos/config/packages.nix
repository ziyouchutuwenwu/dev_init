{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    fd
    ripgrep
    neovim
    git
    wget
    curl
    htop
    tmux
    gcc
    gnumake
    python3
    uv
    file
    which
    killall
    tree
    jq
    ghostty

    chromium
    wpsoffice-cn
    qpdfview
    xnviewmp
    mpv
    qalculate-gtk
    xfce4-taskmanager
    pavucontrol
    gparted
    swappy

    libsForQt5.qt5ct
    kdePackages.qt6ct

    p7zip
    unzip
    zip
    unrar

    (pkgs.writeShellScriptBin "xterm" ''exec ${pkgs.ghostty}/bin/ghostty "$@"'')
    (pkgs.writeShellScriptBin "x-terminal-emulator" ''exec ${pkgs.ghostty}/bin/ghostty "$@"'')
  ];
}
