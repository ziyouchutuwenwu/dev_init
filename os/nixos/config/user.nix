{ ... }:

{
  users.users."mmc" = {
    isNormalUser = true;
    description = "mmc";
    extraGroups = [ "networkmanager" "wheel" "video" "render" "input" ];
  };

  environment.etc."xdg/user-dirs.dirs".text = ''
    XDG_DESKTOP_DIR="$HOME/desktop"
    XDG_DOWNLOAD_DIR="$HOME/downloads"
    XDG_TEMPLATES_DIR="$HOME/.templates"
    XDG_PUBLICSHARE_DIR="$HOME/downloads"
    XDG_DOCUMENTS_DIR="$HOME/downloads"
    XDG_MUSIC_DIR="$HOME/downloads"
    XDG_PICTURES_DIR="$HOME/downloads"
    XDG_VIDEOS_DIR="$HOME/downloads"
  '';

  systemd.user.tmpfiles.rules = [
    "d %h/desktop 0755 - - -"
    "d %h/downloads 0755 - - -"
    "d %h/.templates 0755 - - -"
    "d %h/.config 0755 - - -"
    "d %h/.config/gtk-3.0 0755 - - -"
    "L+ %h/.config/user-dirs.dirs - - - - /etc/xdg/user-dirs.dirs"
    "f+ %h/.config/gtk-3.0/bookmarks 0644 - - - file://%h/downloads"
  ];
}
