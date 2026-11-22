{ pkgs, ... }:

{
  time.timeZone = "Asia/Shanghai";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  fonts = {
    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "slight";
      };
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
      defaultFonts = {
        sansSerif = [ "Noto Sans CJK SC" "Source Han Sans SC" "文泉驿微米黑" "WenQuanYi Micro Hei" "DejaVu Sans" ];
        serif = [ "Noto Serif CJK SC" "Source Han Serif SC" "文泉驿正黑" "WenQuanYi Zen Hei" "DejaVu Serif" ];
        monospace = [ "Monaco" "Noto Sans Mono CJK SC" "文泉驿等宽微米黑" "WenQuanYi Micro Hei Mono" ];
      };
    };
    packages = with pkgs; [
      wqy_microhei
      wqy_zenhei
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      lxgw-wenkai
      corefonts

      nerd-fonts.jetbrains-mono
      font-awesome
    ];
  };
}
