{ pkgs, ... }:

let
  gpicview = pkgs.stdenv.mkDerivation rec {
    pname = "gpicview";
    version = "0.2.5";
    src = pkgs.fetchurl {
      url = "mirror://sourceforge/lxde/${pname}-${version}.tar.xz";
      sha256 = "0hi9v0rdx47nys0wvm9xasdrafa34r5kq6crb074a0ipwmc60iiq";
    };
    nativeBuildInputs = [ pkgs.pkg-config pkgs.intltool pkgs.wrapGAppsHook3 ];
    buildInputs = [ pkgs.gtk3 pkgs.libjpeg ];
    configureFlags = [ "--enable-gtk3" ];
    NIX_CFLAGS_COMPILE = "-Wno-error=return-mismatch -Wno-return-mismatch -Wno-error";
  };
in
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
    qpdfview
    gpicview
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
