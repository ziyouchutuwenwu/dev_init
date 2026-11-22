{ ... }:

{
  environment.sessionVariables = {
    LANG = "zh_CN.UTF-8";
    LC_COLLATE = "zh_CN.UTF-8";

    TERM = "xterm-256color";

    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";

    PYTHONDONTWRITEBYTECODE = "1";

    UV_PYTHON_INSTALL_MIRROR = "https://registry.npmmirror.com/-/binary/python-build-standalone/";
    UV_DEFAULT_INDEX = "https://mirrors.aliyun.com/pypi/simple";

    HEX_UNSAFE_HTTPS = "1";
    HEX_MIRROR = "https://repo.hex.pm";
    HEX_CDN = "https://repo.hex.pm";

    GOOGLE_API_KEY = "";
    GOOGLE_DEFAULT_CLIENT_ID = "";
    GOOGLE_DEFAULT_CLIENT_SECRET = "";

    HTTP_CONNECT_TIMEOUT = "36000";
    HTTP_RECEIVE_TIMEOUT = "36000";
  };

  environment.shellAliases = {
    ls = "ls --color=auto";
    ll = "ls -l --color=auto";
  };

  environment.interactiveShellInit = ''
    pon() {
      export HTTP_PROXY="http://127.0.0.1:8118"
      export HTTPS_PROXY="http://127.0.0.1:8118"
      export ALL_PROXY="socks5://127.0.0.1:1080"
      export NO_PROXY="localhost,127.0.0.1,10.0.2.1"

      export http_proxy="$HTTP_PROXY"
      export https_proxy="$HTTPS_PROXY"
      export all_proxy="$ALL_PROXY"
      export no_proxy="$NO_PROXY"
      echo "终端代理已开启 (HTTP/HTTPS: 8118, SOCKS5: 1080)"
    }

    poff() {
      unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
      unset http_proxy https_proxy all_proxy no_proxy
      echo "终端代理已关闭"
    }
  '';
}
