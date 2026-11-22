{ pkgs, lib, ... }:

{
  programs.labwc = {
    enable = true;
  };

  services.xserver = {
    enable = true;
    excludePackages = [ pkgs.xterm ];
    desktopManager.xterm.enable = false;
    displayManager.lightdm = {
      enable = true;
      background = "/var/lib/lightdm/backgrounds/xfce-blue.jpg";
      greeters.gtk = {
        enable = true;
        theme = {
          name = "Windows10";
        };
        iconTheme = {
          name = "Faenza";
        };
        cursorTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        indicators = [
          "~host"
          "~spacer"
          "~clock"
          "~spacer"
          "~layout"
          "~session"
          "~a11y"
          "~power"
        ];
        extraConfig = ''
          font-name = 文泉驿等宽微米黑 10
          user-background = false
          default-user-image = /var/lib/lightdm/.icons/Faenza/devices/scalable/display.svg
          round-user-image = false
        '';
      };
    };
  };

  services.displayManager = {
    defaultSession = "labwc";
  };

  services.spice-vdagentd.enable = true;

  hardware.graphics.enable = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        qt6Packages.fcitx5-configtool
        fcitx5-gtk
        fcitx5-lua
      ];
    };
  };

  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            gtk-theme = "Windows10";
            icon-theme = "Faenza";
            font-name = "文泉驿等宽微米黑 10";
            monospace-font-name = "Monaco 10";
            cursor-theme = "Adwaita";
            cursor-size = lib.gvariant.mkInt32 24;
            color-scheme = "default";
          };
          "org/gnome/desktop/wm/preferences" = {
            theme = "JacWin10";
            button-layout = "icon:minimize,maximize,close";
            titlebar-font = "文泉驿等宽微米黑 Bold 10";
          };
        };
      }
    ];
  };

  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  environment.variables = {
    SHELL = "/run/current-system/sw/bin/zsh";
    GTK_THEME = "Windows10";
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    TERMINAL = "ghostty";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.upower.enable = true;

  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
  };

  environment.systemPackages = with pkgs; [
    ghostty
    rofi
    thunar
    xarchiver
    swaybg
    sfwbar
    wl-clipboard
    grim
    slurp
    spice-vdagent
    xsettingsd
    glib
    gsettings-desktop-schemas
    adwaita-icon-theme
    networkmanagerapplet
    polkit_gnome
  ];

  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Windows10
    gtk-icon-theme-name=Faenza
    gtk-font-name=文泉驿等宽微米黑 10
    gtk-monospace-font-name=Monaco 10
    gtk-cursor-theme-name=Adwaita
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=false
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintslight
    gtk-xft-rgba=rgb
  '';

  environment.etc."xdg/gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Windows10
    gtk-icon-theme-name=Faenza
    gtk-font-name=文泉驿等宽微米黑 10
    gtk-monospace-font-name=Monaco 10
    gtk-cursor-theme-name=Adwaita
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=false
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintslight
    gtk-xft-rgba=rgb
  '';

  environment.etc."xdg/labwc/rc.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <labwc_config>
      <core>
        <decoration>server</decoration>
        <gap>0</gap>
      </core>

      <placement>
        <policy>center</policy>
      </placement>

      <windowRules>
        <windowRule identifier="*ghostty*">
          <action name="AutoPlace" policy="center" />
          <action name="ResizeTo" width="808" height="459" />
        </windowRule>
      </windowRules>

      <desktops number="10">
        <names>
          <name>1</name>
          <name>2</name>
          <name>3</name>
          <name>4</name>
          <name>5</name>
          <name>6</name>
          <name>7</name>
          <name>8</name>
          <name>9</name>
          <name>10</name>
        </names>
        <popupTime>0</popupTime>
      </desktops>

      <theme>
        <name>JacWin10</name>
        <icon>Faenza</icon>
        <cornerRadius>0</cornerRadius>
        <titlebar>
          <layout>icon:iconify,max,close</layout>
          <showTitle>yes</showTitle>
        </titlebar>
        <font place="ActiveWindow">
          <name>文泉驿等宽微米黑</name>
          <size>10</size>
          <weight>bold</weight>
        </font>
        <font place="InactiveWindow">
          <name>文泉驿等宽微米黑</name>
          <size>10</size>
          <weight>normal</weight>
        </font>
        <font place="MenuItem">
          <name>文泉驿等宽微米黑</name>
          <size>10</size>
        </font>
      </theme>

      <keyboard>
        <default />
        <keybind key="W-Return">
          <action name="Execute" command="ghostty" />
        </keybind>
        <keybind key="W-q">
          <action name="Execute" command="ghostty" />
        </keybind>
        <keybind key="C-A-t">
          <action name="Execute" command="ghostty" />
        </keybind>

        <keybind key="W-space">
          <action name="Execute" command="rofi -show drun -theme /etc/xdg/rofi/w10-start.rasi" />
        </keybind>
        <keybind key="W-r">
          <action name="Execute" command="rofi -show drun -theme /etc/xdg/rofi/w10-start.rasi" />
        </keybind>
        <keybind key="Super_L" onRelease="yes">
          <action name="Execute" command="rofi -show drun -theme /etc/xdg/rofi/w10-start.rasi" />
        </keybind>

        <keybind key="W-e">
          <action name="Execute" command="thunar" />
        </keybind>

        <keybind key="W-c">
          <action name="Close" />
        </keybind>
        <keybind key="A-F4">
          <action name="Close" />
        </keybind>

        <keybind key="W-m">
          <action name="Exit" />
        </keybind>
        <keybind key="W-S-e">
          <action name="Exit" />
        </keybind>

        <keybind key="W-Up">
          <action name="ToggleMaximize" />
        </keybind>
        <keybind key="W-Down">
          <action name="Unmaximize" />
        </keybind>
        <keybind key="W-Left">
          <action name="SnapToEdge" direction="left" />
        </keybind>
        <keybind key="W-Right">
          <action name="SnapToEdge" direction="right" />
        </keybind>

        <keybind key="W-1">
          <action name="GoToDesktop" to="1" />
        </keybind>
        <keybind key="W-2">
          <action name="GoToDesktop" to="2" />
        </keybind>
        <keybind key="W-3">
          <action name="GoToDesktop" to="3" />
        </keybind>
        <keybind key="W-4">
          <action name="GoToDesktop" to="4" />
        </keybind>
        <keybind key="W-5">
          <action name="GoToDesktop" to="5" />
        </keybind>
        <keybind key="W-6">
          <action name="GoToDesktop" to="6" />
        </keybind>
        <keybind key="W-7">
          <action name="GoToDesktop" to="7" />
        </keybind>
        <keybind key="W-8">
          <action name="GoToDesktop" to="8" />
        </keybind>
        <keybind key="W-9">
          <action name="GoToDesktop" to="9" />
        </keybind>
        <keybind key="W-0">
          <action name="GoToDesktop" to="10" />
        </keybind>
        <keybind key="W-Left">
          <action name="GoToDesktop" to="left" wrap="yes" />
        </keybind>
        <keybind key="W-Right">
          <action name="GoToDesktop" to="right" wrap="yes" />
        </keybind>
        <keybind key="C-A-Left">
          <action name="GoToDesktop" to="left" wrap="yes" />
        </keybind>
        <keybind key="C-A-Right">
          <action name="GoToDesktop" to="right" wrap="yes" />
        </keybind>

        <keybind key="W-S-1">
          <action name="SendToDesktop" to="1" follow="yes" />
        </keybind>
        <keybind key="W-S-2">
          <action name="SendToDesktop" to="2" follow="yes" />
        </keybind>
        <keybind key="W-S-3">
          <action name="SendToDesktop" to="3" follow="yes" />
        </keybind>
        <keybind key="W-S-4">
          <action name="SendToDesktop" to="4" follow="yes" />
        </keybind>
        <keybind key="W-S-5">
          <action name="SendToDesktop" to="5" follow="yes" />
        </keybind>
        <keybind key="W-S-6">
          <action name="SendToDesktop" to="6" follow="yes" />
        </keybind>
        <keybind key="W-S-7">
          <action name="SendToDesktop" to="7" follow="yes" />
        </keybind>
        <keybind key="W-S-8">
          <action name="SendToDesktop" to="8" follow="yes" />
        </keybind>
        <keybind key="W-S-9">
          <action name="SendToDesktop" to="9" follow="yes" />
        </keybind>
        <keybind key="W-S-0">
          <action name="SendToDesktop" to="10" follow="yes" />
        </keybind>
        <keybind key="W-S-Left">
          <action name="SendToDesktop" to="left" follow="yes" wrap="yes" />
        </keybind>
        <keybind key="W-S-Right">
          <action name="SendToDesktop" to="right" follow="yes" wrap="yes" />
        </keybind>
      </keyboard>

      <mouse>
        <default />
        <context name="Root">
          <mousebind button="Left" action="Press" />
          <mousebind button="Left" action="Click" />
          <mousebind button="Middle" action="Press" />
          <mousebind button="Middle" action="Click" />
          <mousebind button="Right" action="Press">
            <action name="ShowMenu" menu="root-menu" />
          </mousebind>
          <mousebind direction="Up" action="Scroll">
            <action name="GoToDesktop" to="left" wrap="yes" />
          </mousebind>
          <mousebind direction="Down" action="Scroll">
            <action name="GoToDesktop" to="right" wrap="yes" />
          </mousebind>
        </context>
        <context name="Desktop">
          <mousebind button="Left" action="Press" />
          <mousebind button="Left" action="Click" />
          <mousebind button="Middle" action="Press" />
          <mousebind button="Middle" action="Click" />
          <mousebind button="Right" action="Press">
            <action name="ShowMenu" menu="root-menu" />
          </mousebind>
        </context>
      </mouse>

      <menu>
        <ignoreButtonReleasePeriod>400</ignoreButtonReleasePeriod>
        <showIcons>yes</showIcons>
      </menu>
    </labwc_config>
  '';

  environment.etc."xdg/labwc/menu.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <openbox_menu>
      <menu id="root-menu" label="Labwc">
        <item label="终端">
          <action name="Execute" command="ghostty" />
        </item>
        <item label="应用启动">
          <action name="Execute" command="rofi -show drun -theme /etc/xdg/rofi/w10-start.rasi" />
        </item>
        <item label="文件管理器">
          <action name="Execute" command="thunar" />
        </item>
        <separator />
        <menu id="desktops-menu" label="虚拟桌面">
          <item label="工作区 1">
            <action name="GoToDesktop" to="1" />
          </item>
          <item label="工作区 2">
            <action name="GoToDesktop" to="2" />
          </item>
          <item label="工作区 3">
            <action name="GoToDesktop" to="3" />
          </item>
          <item label="工作区 4">
            <action name="GoToDesktop" to="4" />
          </item>
          <item label="工作区 5">
            <action name="GoToDesktop" to="5" />
          </item>
          <item label="工作区 6">
            <action name="GoToDesktop" to="6" />
          </item>
          <item label="工作区 7">
            <action name="GoToDesktop" to="7" />
          </item>
          <item label="工作区 8">
            <action name="GoToDesktop" to="8" />
          </item>
          <item label="工作区 9">
            <action name="GoToDesktop" to="9" />
          </item>
          <item label="工作区 10">
            <action name="GoToDesktop" to="10" />
          </item>
        </menu>
        <separator />
        <item label="重新加载配置">
          <action name="Reconfigure" />
        </item>
        <item label="注销会话">
          <action name="Exit" />
        </item>
        <item label="重启系统">
          <action name="Execute" command="systemctl reboot" />
        </item>
        <item label="关闭系统">
          <action name="Execute" command="systemctl poweroff" />
        </item>
      </menu>
    </openbox_menu>
  '';

  environment.etc."xdg/labwc/autostart".text = ''
    spice-vdagent &
    xsettingsd &
    ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
    fcitx5 -d &
    if [ -f "$HOME/.local/share/backgrounds/xfce/xfce-blue.jpg" ]; then
      swaybg -i "$HOME/.local/share/backgrounds/xfce/xfce-blue.jpg" -m fill &
    elif [ -f "/run/current-system/sw/share/backgrounds/xfce/xfce-blue.jpg" ]; then
      swaybg -i /run/current-system/sw/share/backgrounds/xfce/xfce-blue.jpg -m fill &
    else
      swaybg -c "#2c3e50" &
    fi
    (sleep 0.8; pkill -x sfwbar 2>/dev/null; sfwbar -f /etc/xdg/sfwbar/w10.config) &
  '';

  environment.etc."xdg/labwc/environment".text = ''
    SHELL=/run/current-system/sw/bin/zsh
    XDG_CURRENT_DESKTOP=labwc:wlroots
    XDG_SESSION_TYPE=wayland
    XDG_SESSION_DESKTOP=labwc
    MOZ_ENABLE_WAYLAND=1
    QT_QPA_PLATFORM=wayland;xcb
    XCURSOR_THEME=Adwaita
    XCURSOR_SIZE=24
    GTK_IM_MODULE=fcitx
    QT_IM_MODULE=fcitx
    XMODIFIERS=@im=fcitx
    SDL_IM_MODULE=fcitx
    GLFW_IM_MODULE=ibus
    WLR_NO_HARDWARE_CURSORS=1
    WLR_RENDERER_ALLOW_SOFTWARE=1
  '';

  environment.etc."xdg/xsettingsd/xsettingsd.conf".text = ''
    Net/ThemeName "Windows10"
    Net/IconThemeName "Faenza"
    Gtk/FontName "文泉驿等宽微米黑 10"
    Gtk/CursorThemeName "Adwaita"
    Gtk/CursorThemeSize 24
    Net/EnableEventSounds 0
    Net/EnableInputFeedbackSounds 0
    Xft/Antialias 1
    Xft/Hinting 1
    Xft/HintStyle "hintslight"
    Xft/RGBA "rgb"
  '';

  environment.etc."xdg/sfwbar/power.widget".text = ''
    menu("power_menu") {
      item {
        value = "注销";
        icon = "system-log-out";
        action = Exec("labwc -e");
      }
      item {
        value = "重启";
        icon = "system-reboot";
        action = Exec("systemctl reboot");
      }
      item {
        value = "关机";
        icon = "system-shutdown";
        action = Exec("systemctl poweroff");
      }
    }

    Private {
      layout {
        button {
          value = "system-shutdown"
          style = "power_btn"
          tooltip = "电源与会话管理 (点击展开)"
          action = Menu("power_menu")
          action[RightClick] = Menu("power_menu")
        }
      }
    }
  '';

  environment.etc."xdg/sfwbar/w10.config".text = ''
    #Api2
    Set ImagePath = "icons/misc"
    Set ThicknessHint = "26px";

    TriggerAction "SIGRTMIN+1", SwitcherEvent("forward");
    TriggerAction "SIGRTMIN+2", SwitcherEvent("back");

    placer {
      xorigin = 5
      yorigin = 5
      xstep = 5
      ystep = 5
      children = true
    }

    switcher {
      icons = true
      labels = false
      cols = 5
    }

    include("winops.widget")
    module("network")
    include("wifi.widget")

    layout "sfwbar" {
      layer = "top"
      bar_id = "bar-0"
      mirror = "*"
      exclusive_zone = "auto"

      include("showdesktop.widget")

      taskbar {
        rows = 1;
        tooltips = true;
        icons = true;
        labels = true;
        action[RightClick] = Menu("winops");
      }

      label { css = "* { -GtkWidget-hexpand: true; }" }

      tray {
        rows = 1;
        style = "tray";
      }

      button {
        value = If(NetInfo("ip") != "", "network-wired", "network-wired-disconnected")
        style = "net_wired"
        tooltip = "有线网络: " + If(NetInfo("ip") != "", NetInfo("interface") + " (" + NetInfo("ip") + ")", "未连接")
        action = Exec("nm-connection-editor")
        action[RightClick] = Exec("ghostty -e nmtui")
      }

      button {
        value = If(NetInfo("essid") != "", "network-wireless-signal-excellent", "network-wireless")
        style = "net_wifi"
        tooltip = "无线网络: " + If(NetInfo("essid") != "", NetInfo("essid") + " (" + Str(NetStat("signal")) + "%)", "未连接 / 未启用")
        action = PopUp("XWifiWindow")
        action[RightClick] = Exec("nm-connection-editor")
      }

      widget "volume.widget" {
        simple_icon = true;
      }

      widget "clock.widget" {
        disable = false;
        time_format = "%Y-%m-%d  %H:%M:%S";
        tooltip_format = "%Y年%m月%d日 %A";
        week_starts_on_sunday = false;
        reset_on_popup = false;
      }

      include("/etc/xdg/sfwbar/power.widget")
    }

    #CSS
    @define-color bar_bg #f0f0f0;
    @define-color bar_border #d0d0d0;
    @define-color item_hover rgba(0, 0, 0, 0.06);
    @define-color item_active rgba(0, 0, 0, 0.12);
    @define-color win_accent #0078d7;
    @define-color text_color #222222;

    window {
      -GtkWidget-direction: bottom;
      min-height: 26px;
      background-color: @bar_bg;
      border-top: 1px solid @bar_border;
    }

    #hidden {
      -GtkWidget-visible: false;
    }

    label {
      font-family: "文泉驿等宽微米黑", sans-serif;
      font-size: 11px;
      color: @text_color;
      text-shadow: none;
    }

    button,
    button image {
      outline-style: none;
      outline: none;
      box-shadow: none;
      background-image: none;
      border-image: none;
    }

    button#showdesktop {
      border: 0;
      outline: none;
      border-radius: 0;
      min-width: 26px;
      min-height: 26px;
      margin: 0;
      padding: 0 4px;
      background: transparent;
      -GtkWidget-valign: center;
      -GtkWidget-vexpand: true;
    }

    button#showdesktop:hover {
      background-color: rgba(0, 0, 0, 0.08);
    }

    button#showdesktop image {
      min-width: 16px;
      min-height: 16px;
      -ScaleImage-symbolic: false;
      -GtkWidget-halign: center;
      -GtkWidget-valign: center;
    }

    button#taskbar_item {
      border-radius: 2px;
      border: 1px solid #b8b8b8;
      outline: none;
      box-shadow: none;
      background: linear-gradient(to bottom, #fcfcfc, #e2e2e2);
      min-height: 20px;
      padding: 0 6px;
      margin: 2px 2px;
      -GtkWidget-valign: center;
      -GtkWidget-hexpand: false;
    }

    button#taskbar_item grid {
      -GtkWidget-valign: center;
      -GtkWidget-vexpand: true;
    }

    button#taskbar_item:focus {
      outline: none;
    }

    button#taskbar_item:hover {
      background: linear-gradient(to bottom, #f0f7fe, #d6ebfb);
      border: 1px solid #70c0e7;
    }

    button#taskbar_item.active,
    button#taskbar_item.focused,
    button#taskbar_item:focus.active {
      background: linear-gradient(to bottom, #e2f1fc, #c5e4fc);
      border: 1px solid #2680eb;
    }

    button#taskbar_item image {
      min-width: 16px;
      min-height: 16px;
      padding-right: 4px;
      -ScaleImage-symbolic: false;
      -GtkWidget-valign: center;
    }

    button#taskbar_item label {
      color: #111111;
      font-size: 11px;
      -GtkWidget-hexpand: false;
      -GtkWidget-halign: start;
      -GtkWidget-valign: center;
      margin: 0;
      padding: 0;
    }

    grid#tray {
      margin: 0 4px 0 2px;
      padding: 0 4px;
      border-left: 1px solid #d0d0d0;
      -GtkWidget-valign: center;
      -GtkWidget-vexpand: true;
    }

    button#tray_item,
    button#tray_active,
    button#tray_passive,
    button#tray_attention {
      border: 0;
      outline: none;
      border-radius: 2px;
      background: transparent;
      padding: 0 2px;
      margin: 0;
      min-width: 18px;
      min-height: 20px;
      -GtkWidget-valign: center;
      -GtkWidget-vexpand: true;
    }

    button#tray_item:hover,
    button#tray_active:hover {
      background-color: rgba(0, 0, 0, 0.08);
    }

    button#tray_item image,
    button#tray_active image,
    button#tray_passive image,
    button#tray_attention image {
      min-width: 16px;
      min-height: 16px;
      -ScaleImage-symbolic: true;
      -GtkWidget-halign: center;
      -GtkWidget-valign: center;
      -GtkWidget-vexpand: true;
    }

    button#tray_item label,
    button#tray_active label {
      font-size: 11px;
      color: #111111;
      -GtkWidget-halign: center;
      -GtkWidget-valign: center;
      -GtkWidget-vexpand: true;
    }

    button#net_wired,
    button#net_wifi {
      border: 0;
      outline: none;
      border-radius: 2px;
      background: transparent;
      padding: 0 2px;
      margin: 0 1px;
      min-width: 20px;
      min-height: 20px;
      -GtkWidget-valign: center;
      -GtkWidget-vexpand: true;
    }

    button#net_wired:hover,
    button#net_wifi:hover {
      background-color: rgba(0, 0, 0, 0.08);
    }

    button#net_wired image,
    button#net_wifi image {
      min-width: 16px;
      min-height: 16px;
      -ScaleImage-symbolic: true;
      color: #111111;
      -GtkWidget-halign: center;
      -GtkWidget-valign: center;
      -GtkWidget-vexpand: true;
    }

    .module,
    button#module,
    button#volume {
      border: 0;
      outline: none;
      border-radius: 2px;
      background: transparent;
      padding: 0 2px;
      min-width: 20px;
      min-height: 20px;
      -GtkWidget-valign: center;
    }

    button#volume:hover,
    button#module:hover {
      background-color: rgba(0, 0, 0, 0.08);
    }

    button#volume image,
    button#module image {
      min-width: 16px;
      min-height: 16px;
      -ScaleImage-symbolic: true;
      color: #111111;
      -GtkWidget-valign: center;
    }

    label#clock {
      color: #111111;
      font-family: "文泉驿等宽微米黑", sans-serif;
      font-size: 11px;
      padding: 0 4px;
      margin: 0 2px;
      -GtkWidget-valign: center;
      -GtkLabel-align: 0.5;
    }

    label#clock:hover {
      background-color: rgba(0, 0, 0, 0.08);
      border-radius: 2px;
    }

    button#power_btn {
      border: 0;
      outline: none;
      border-radius: 2px;
      background: transparent;
      padding: 0 4px;
      margin: 0 2px 0 2px;
      min-width: 22px;
      min-height: 20px;
      border-left: 1px solid #d0d0d0;
      -GtkWidget-valign: center;
      -GtkWidget-vexpand: true;
    }

    button#power_btn:hover {
      background-color: rgba(235, 50, 50, 0.15);
    }

    button#power_btn image {
      min-width: 16px;
      min-height: 16px;
      -ScaleImage-symbolic: true;
      color: #d93838;
      -GtkWidget-halign: center;
      -GtkWidget-valign: center;
    }

    menu {
      background-color: #ffffff;
      border: 1px solid #b8b8b8;
      border-radius: 4px;
      padding: 4px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.15);
    }

    menuitem {
      padding: 6px 14px;
      margin: 1px 0;
      border-radius: 3px;
      color: #222222;
    }

    menuitem:hover {
      background-color: rgba(0, 120, 215, 0.15);
      color: #000000;
    }

    menuitem label {
      font-family: "文泉驿等宽微米黑", sans-serif;
      font-size: 12px;
      padding-left: 8px;
    }

    menuitem image {
      min-width: 16px;
      min-height: 16px;
    }

    window#taskbar_popup,
    window#cal,
    window#Xcal,
    window#XVolumeWindow {
      background-color: #ffffff;
      border: 1px solid #b8b8b8;
      border-radius: 3px;
      padding: 6px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    }

    calendar {
      background-color: #ffffff;
      color: #222222;
    }

    calendar:selected {
      background-color: @win_accent;
      color: #ffffff;
    }

    menu {
      background-color: #ffffff;
      border: 1px solid #b8b8b8;
      padding: 4px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    }

    #menu_item label {
      color: #222222;
      font-size: 11px;
      padding: 4px 8px;
    }

    #menu_item:hover {
      background-color: @win_accent;
    }

    #menu_item:hover label {
      color: #ffffff;
    }
  '';

  environment.etc."xdg/rofi/w10-start.rasi".text = ''
    configuration {
        modi: "drun";
        show-icons: true;
        icon-theme: "Faenza";
        font: "文泉驿等宽微米黑 10";
        drun-display-format: "{name}";
        terminal: "ghostty";
    }

    * {
        background-color: transparent;
        text-color: #222222;
    }

    window {
        location: center;
        anchor: center;
        x-offset: 0px;
        y-offset: 0px;
        width: 380px;
        height: 500px;
        background-color: #ffffff;
        border: 1px;
        border-color: #bbbbbb;
        border-radius: 6px;
        padding: 10px;
    }

    mainbox {
        children: [ "inputbar", "listview" ];
        spacing: 8px;
        padding: 0px;
    }

    inputbar {
        children: [ "entry" ];
        background-color: #f3f3f3;
        border: 1px;
        border-color: #cccccc;
        padding: 6px 8px;
    }

    entry {
        text-color: #222222;
        placeholder: "搜索应用...";
        placeholder-color: #888888;
    }

    listview {
        columns: 1;
        lines: 10;
        scrollbar: false;
        spacing: 2px;
    }

    element {
        padding: 6px 8px;
        spacing: 8px;
    }

    element selected.normal {
        background-color: #0078d7;
        text-color: #ffffff;
    }

    element-icon {
        size: 22px;
    }

    element-text {
        vertical-align: 0.5;
        text-color: inherit;
    }
  '';

  environment.etc."xdg/fcitx5/profile".text = ''
    [Groups/0]
    Name=默认
    Default Layout=us
    DefaultIM=pinyin

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=pinyin
    Layout=

    [GroupOrder]
    0=默认
  '';

  environment.etc."xdg/Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
    	<icon>utilities-terminal</icon>
    	<name>终端</name>
    	<submenu></submenu>
    	<unique-id>1795183774115462-1</unique-id>
    	<command>ghostty --working-directory=%f</command>
    	<description>在此处打开 Ghostty 终端</description>
    	<range></range>
    	<patterns>*</patterns>
    	<startup-notify/>
    	<directories/>
    </action>
    </actions>
  '';

  environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
    <?xml version="1.1" encoding="UTF-8"?>
    <channel name="thunar" version="1.0">
      <property name="last-view" type="string" value="ThunarIconView"/>
      <property name="last-icon-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_50_PERCENT"/>
      <property name="misc-single-click" type="bool" value="false"/>
      <property name="last-separator-position" type="int" value="170"/>
      <property name="last-toolbar-items" type="string" value="menu:0,back:1,forward:1,open-parent:1,open-home:1,new-tab:0,new-window:0,toggle-split-view:0,undo:0,redo:0,zoom-out:0,zoom-in:0,zoom-reset:0,view-as-icons:0,view-as-detailed-list:0,view-as-compact-list:0,view-switcher:0,location-bar:1,reload:0,search:0,uca-action-1795183774115462-1:1"/>
      <property name="last-window-width" type="int" value="893"/>
      <property name="last-window-height" type="int" value="484"/>
      <property name="last-window-maximized" type="bool" value="false"/>
      <property name="misc-date-style" type="string" value="THUNAR_DATE_STYLE_YYYYMMDD"/>
    </channel>
  '';

  system.activationScripts.userGtkSettings = {
    text = ''
    if [ -d "/home/mmc" ]; then
      rm -f /home/mmc/.config/gtk-3.0/settings.ini /home/mmc/.config/gtk-4.0/settings.ini
      rm -rf /home/mmc/.config/sfwbar

      mkdir -p /home/mmc/.config/fcitx5
      cp -f /etc/xdg/fcitx5/profile /home/mmc/.config/fcitx5/profile 2>/dev/null || true

      rm -f /home/mmc/.tmux.conf
      if [ -f "/etc/nixos/config/extra/tmux/tmux.conf" ]; then
        cp -f /etc/nixos/config/extra/tmux/tmux.conf /etc/tmux.conf 2>/dev/null || true
      elif [ -f "/etc/nixos/extra/tmux/tmux.conf" ]; then
        cp -f /etc/nixos/extra/tmux/tmux.conf /etc/tmux.conf 2>/dev/null || true
      fi

      mkdir -p /home/mmc/.config/Thunar /home/mmc/.config/xfce4/xfconf/xfce-perchannel-xml
      cp -n /etc/xdg/Thunar/uca.xml /home/mmc/.config/Thunar/uca.xml 2>/dev/null || true
      cp -n /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/thunar.xml /home/mmc/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml 2>/dev/null || true

      mkdir -p /home/mmc/desktop /home/mmc/downloads /home/mmc/.templates /home/mmc/.config/gtk-3.0
      ln -sf /etc/xdg/user-dirs.dirs /home/mmc/.config/user-dirs.dirs
      if [ ! -f "/home/mmc/.config/gtk-3.0/bookmarks" ] || ! grep -q "/home/mmc/downloads" /home/mmc/.config/gtk-3.0/bookmarks; then
        echo "file:///home/mmc/downloads" >> /home/mmc/.config/gtk-3.0/bookmarks
      fi
      chown -R mmc:users /home/mmc/desktop /home/mmc/downloads /home/mmc/.templates /home/mmc/.config/gtk-3.0 /home/mmc/.config/user-dirs.dirs 2>/dev/null || true

      if [ -f "/home/mmc/.config/ghostty/config" ]; then
        sed -i 's/^window-width = .*/window-width = 80/; s/^window-height = .*/window-height = 21/' /home/mmc/.config/ghostty/config 2>/dev/null || true
        grep -q "^command = zsh" /home/mmc/.config/ghostty/config 2>/dev/null || sed -i '/window-height =/a command = zsh' /home/mmc/.config/ghostty/config 2>/dev/null || true
      fi

      EXTRA_DIR=""
      if [ -d "/etc/nixos/config/extra" ]; then
        EXTRA_DIR="/etc/nixos/config/extra"
      elif [ -d "/etc/nixos/extra" ]; then
        EXTRA_DIR="/etc/nixos/extra"
      fi

      if [ -n "$EXTRA_DIR" ]; then
        echo "==> 检测到 $EXTRA_DIR，执行安装期扩展资产部署..."

        mkdir -p /var/lib/lightdm/backgrounds /var/lib/lightdm/.themes /var/lib/lightdm/.icons /var/lib/lightdm/.config/gtk-3.0
        cp -rf $EXTRA_DIR/backgrounds/* /var/lib/lightdm/backgrounds/ 2>/dev/null || true
        cp -rf $EXTRA_DIR/themes/* /var/lib/lightdm/.themes/ 2>/dev/null || true
        cp -rf $EXTRA_DIR/icons/* /var/lib/lightdm/.icons/ 2>/dev/null || true
        echo -e "#user_image, #user_image_border { border-radius: 2px; -gtk-outline-radius: 2px; }\n#user_image { border-radius: 2px; }" > /var/lib/lightdm/.config/gtk-3.0/gtk.css
        gtk-update-icon-cache /var/lib/lightdm/.icons/Faenza 2>/dev/null || true
        chown -R lightdm:lightdm /var/lib/lightdm 2>/dev/null || true

        if [ -d "$EXTRA_DIR/fonts" ]; then
          mkdir -p /home/mmc/.local/share/fonts
          cp -rf $EXTRA_DIR/fonts/* /home/mmc/.local/share/fonts/ 2>/dev/null || true
          fc-cache -f /home/mmc/.local/share/fonts 2>/dev/null || true
        fi

        if [ -d "$EXTRA_DIR/backgrounds" ]; then
          mkdir -p /home/mmc/.local/share/backgrounds/xfce
          cp -rf $EXTRA_DIR/backgrounds/* /home/mmc/.local/share/backgrounds/xfce/ 2>/dev/null || true
        fi

        if [ -d "$EXTRA_DIR/themes" ]; then
          mkdir -p /home/mmc/.local/share/themes /home/mmc/.themes
          cp -rf $EXTRA_DIR/themes/* /home/mmc/.local/share/themes/ 2>/dev/null || true
          cp -rf $EXTRA_DIR/themes/* /home/mmc/.themes/ 2>/dev/null || true
        fi

        if [ -d "$EXTRA_DIR/icons" ]; then
          mkdir -p /home/mmc/.local/share/icons /home/mmc/.icons
          cp -rf $EXTRA_DIR/icons/* /home/mmc/.local/share/icons/ 2>/dev/null || true
          cp -rf $EXTRA_DIR/icons/* /home/mmc/.icons/ 2>/dev/null || true
          gtk-update-icon-cache /home/mmc/.local/share/icons/Faenza 2>/dev/null || true
          gtk-update-icon-cache /home/mmc/.icons/Faenza 2>/dev/null || true
        fi

        if [ -d "$EXTRA_DIR/ghostty" ]; then
          mkdir -p /home/mmc/.config/ghostty/css /home/mmc/.config/ghostty/themes
          cp -rf $EXTRA_DIR/ghostty/config /home/mmc/.config/ghostty/config 2>/dev/null || true
          cp -rf $EXTRA_DIR/ghostty/css/* /home/mmc/.config/ghostty/css/ 2>/dev/null || true
          cp -rf $EXTRA_DIR/ghostty/themes/* /home/mmc/.config/ghostty/themes/ 2>/dev/null || true
        fi

        if [ -d "$EXTRA_DIR/fcitx5" ]; then
          mkdir -p /home/mmc/.config/fcitx5/conf /home/mmc/.local/share/fcitx5/themes/custom /home/mmc/.local/share/fcitx5/pinyin
          cp -rf $EXTRA_DIR/fcitx5/config/config /home/mmc/.config/fcitx5/config 2>/dev/null || true
          cp -rf $EXTRA_DIR/fcitx5/config/conf/* /home/mmc/.config/fcitx5/conf/ 2>/dev/null || true
          cp -rf $EXTRA_DIR/fcitx5/local/themes/custom/* /home/mmc/.local/share/fcitx5/themes/custom/ 2>/dev/null || true
          cp -rf $EXTRA_DIR/fcitx5/local/pinyin/* /home/mmc/.local/share/fcitx5/pinyin/ 2>/dev/null || true
        fi

      fi

      mkdir -p /home/mmc/.local/share/applications

      for hidden_app in \
        fcitx5-migrator \
        fcitx5-wayland-launcher \
        kbd-layout-viewer5 \
        kcm_fcitx5 \
        nixos-manual \
        org.fcitx.Fcitx5 \
        org.fcitx.fcitx5-migrator \
        org.fcitx.fcitx5-qt5-gui-wrapper \
        org.fcitx.fcitx5-qt6-gui-wrapper \
        org.freedesktop.Xwayland \
        rofi \
        rofi-theme-selector \
        thunar-bulk-rename \
        thunar-settings \
        thunar-volman-settings \
        xdg-desktop-portal-gtk; do
        cat <<EOF > /home/mmc/.local/share/applications/$hidden_app.desktop
[Desktop Entry]
Type=Application
Name=hidden
NoDisplay=true
EOF
      done

      cat <<EOF > /home/mmc/.local/share/applications/com.mitchellh.ghostty.desktop
[Desktop Entry]
Type=Application
Name=终端
Name[zh_CN]=终端
GenericName=终端模拟器
Exec=ghostty
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/htop.desktop
[Desktop Entry]
Type=Application
Name=系统监控
Name[zh_CN]=系统监控
GenericName=进程监控
Exec=ghostty -e htop
Icon=htop
Terminal=false
Categories=System;Monitor;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/qalculate-gtk.desktop
[Desktop Entry]
Type=Application
Name=计算器
Name[zh_CN]=计算器
GenericName=科学计算器
Exec=qalculate-gtk
Icon=qalculate
Terminal=false
Categories=Utility;Calculator;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/nm-connection-editor.desktop
[Desktop Entry]
Type=Application
Name=网络配置
Name[zh_CN]=网络配置
GenericName=网络设置
Exec=nm-connection-editor
Icon=preferences-system-network
Terminal=false
Categories=Settings;HardwareSettings;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/xarchiver.desktop
[Desktop Entry]
Type=Application
Name=归档解压
Name[zh_CN]=归档解压
GenericName=压缩解压工具
Exec=xarchiver %F
Icon=xarchiver
Terminal=false
Categories=Utility;Archiving;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/qpdfview.desktop
[Desktop Entry]
Type=Application
Name=PDF阅读器
Name[zh_CN]=PDF阅读器
GenericName=文档阅读器
Exec=qpdfview --unique %F
Icon=qpdfview
Terminal=false
Categories=Office;Viewer;
EOF

      rm -f /home/mmc/.local/share/applications/qview.desktop /home/mmc/.local/share/applications/mousepad.desktop /home/mmc/.local/share/applications/btop.desktop /home/mmc/.local/share/applications/xnviewmp.desktop /home/mmc/.local/share/applications/*wps*

      cat <<EOF > /home/mmc/.local/share/applications/gpicview.desktop
[Desktop Entry]
Type=Application
Name=图片查看器
Name[zh_CN]=图片查看器
GenericName=图片查看器 (GPicView)
Exec=gpicview %F
Icon=gpicview
Terminal=false
Categories=Graphics;Viewer;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/nvim.desktop
[Desktop Entry]
Type=Application
Name=文本编辑器
Name[zh_CN]=文本编辑器
GenericName=文本编辑器 (Neovim)
Exec=ghostty -e nvim %F
Icon=nvim
Terminal=false
Categories=Utility;TextEditor;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/xfce4-taskmanager.desktop
[Desktop Entry]
Type=Application
Name=任务管理器
Name[zh_CN]=任务管理器
GenericName=任务管理器
Exec=xfce4-taskmanager
Icon=org.xfce.taskmanager
Terminal=false
Categories=System;Monitor;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/qt5ct.desktop
[Desktop Entry]
Type=Application
Name=Qt5 设置
Name[zh_CN]=Qt5 设置
GenericName=Qt5 外观与字体配置
Exec=qt5ct
Icon=preferences-desktop-theme
Terminal=false
Categories=Settings;DesktopSettings;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/qt6ct.desktop
[Desktop Entry]
Type=Application
Name=Qt6 设置
Name[zh_CN]=Qt6 设置
GenericName=Qt6 外观与字体配置
Exec=qt6ct
Icon=preferences-desktop-theme
Terminal=false
Categories=Settings;DesktopSettings;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/pavucontrol.desktop
[Desktop Entry]
Type=Application
Name=音量控制
Name[zh_CN]=音量控制
GenericName=音频调音台
Exec=pavucontrol
Icon=multimedia-volume-control
Terminal=false
Categories=AudioVideo;Audio;Mixer;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/chromium.desktop
[Desktop Entry]
Type=Application
Name=Chromium
Name[zh_CN]=Chromium
GenericName=网页浏览器
Exec=chromium %U
Icon=chromium
Terminal=false
Categories=Network;WebBrowser;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/mpv.desktop
[Desktop Entry]
Type=Application
Name=MPV播放器
Name[zh_CN]=MPV播放器
GenericName=媒体播放器
Exec=mpv --player-operation-mode=pseudo-gui -- %U
Icon=mpv
Terminal=false
Categories=AudioVideo;Player;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/gparted.desktop
[Desktop Entry]
Type=Application
Name=gparted
Name[zh_CN]=gparted
GenericName=磁盘与分区管理
Exec=gparted %f
Icon=gparted
Terminal=false
Categories=System;Filesystem;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/thunar.desktop
[Desktop Entry]
Type=Application
Name=thunar
Name[zh_CN]=thunar
GenericName=文件管理器
Exec=thunar %F
Icon=thunar
Terminal=false
Categories=System;FileManager;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/system-shutdown.desktop
[Desktop Entry]
Type=Application
Name=关闭系统
Name[zh_CN]=关闭系统
Exec=systemctl poweroff
Icon=system-shutdown
Terminal=false
Categories=System;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/system-reboot.desktop
[Desktop Entry]
Type=Application
Name=重启系统
Name[zh_CN]=重启系统
Exec=systemctl reboot
Icon=system-reboot
Terminal=false
Categories=System;
EOF

      cat <<EOF > /home/mmc/.local/share/applications/system-log-out.desktop
[Desktop Entry]
Type=Application
Name=注销会话
Name[zh_CN]=注销会话
Exec=labwc -e
Icon=system-log-out
Terminal=false
Categories=System;
EOF

      mkdir -p /home/mmc/.config
      cat <<EOF > /home/mmc/.config/mimeapps.list
[Default Applications]
application/pdf=qpdfview.desktop;
application/x-pdf=qpdfview.desktop;
image/png=gpicview.desktop;
image/jpeg=gpicview.desktop;
image/gif=gpicview.desktop;
image/webp=gpicview.desktop;
image/bmp=gpicview.desktop;
image/svg+xml=gpicview.desktop;
text/plain=nvim.desktop;
video/mp4=mpv.desktop;
video/mkv=mpv.desktop;
video/webm=mpv.desktop;
video/x-matroska=mpv.desktop;
audio/mpeg=mpv.desktop;
audio/flac=mpv.desktop;
text/html=chromium.desktop;
x-scheme-handler/http=chromium.desktop;
x-scheme-handler/https=chromium.desktop;
EOF

      chown -R mmc:users /home/mmc/.local /home/mmc/.themes /home/mmc/.config /home/mmc/.icons 2>/dev/null || true
    fi
  '';
};
}
