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
        sansSerif = [ "WenQuanYi Micro Hei Mono" "文泉驿等宽微米黑" "WenQuanYi Micro Hei" "文泉驿微米黑" ];
        serif = [ "WenQuanYi Micro Hei Mono" "文泉驿等宽微米黑" "WenQuanYi Zen Hei" "文泉驿正黑" ];
        monospace = [ "Monaco" "WenQuanYi Micro Hei Mono" "文泉驿等宽微米黑" "JetBrainsMono Nerd Font" ];
      };
    };
    packages = with pkgs; [
      wqy_microhei
      wqy_zenhei
      nerd-fonts.jetbrains-mono
      font-awesome

      (runCommand "monaco-font" {} ''
        install -D -m644 ${./extra/fonts/Monaco-Linux.ttf} $out/share/fonts/truetype/Monaco-Linux.ttf
      '')
    ];
  };
}
