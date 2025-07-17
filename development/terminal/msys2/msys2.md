# msys2

## 说明

建议用 mingw64 的 shell, 编译出来的依赖库最少

## 配置

### 换源

```sh
sed -i "s#mirror.msys2.org/#mirrors.ustc.edu.cn/msys2/#g" /etc/pacman.d/mirrorlist*
```

### 工具

```sh
pacman -Syyu --noconfirm
pacman -S --noconfirm base-devel vim curl axel git
```

mingw

```sh
pacman -S mingw-w64-x86_64-python-uv
pacman -S mingw-w64-x86_64-fd
pacman -S mingw-w64-x86_64-ag
```

### profile

/etc/profile.d/proxy.sh

```sh
alias pon="export HTTP_PROXY=http://10.0.2.1:8118 HTTPS_PROXY=http://10.0.2.1:8118 ALL_PROXY=socks5://10.0.2.1:1080"
alias poff="unset HTTP_PROXY HTTPS_PROXY ALL_PROXY"
```

/etc/profile.d/ls.sh

```sh
alias ll='ls -la --color=auto' 2>/dev/null
alias l.='ls --color=auto -d .*' 2>/dev/null
alias ls='ls --color=auto' 2>/dev/null
```

/etc/profile.d/python.sh

```sh
export PYTHONPYCACHEPREFIX=/dev/null
export UV_INDEX="https://mirrors.aliyun.com/pypi/simple"
```
