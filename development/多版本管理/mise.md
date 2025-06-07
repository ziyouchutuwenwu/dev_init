# mise

## 说明

多版本管理工具，支持多种后端，自动选择，更好用

## 用法

### 安装

```sh
curl https://mise.run | sh
```

~/.profile

```sh
eval "$(mise activate zsh)"
```

所在路径

```sh
$HOME/.local/bin/mise
$HOME/.config/mise/
$HOME/.local/share/mise/
$HOME/.local/state/mise/
```

### 基本用法

```sh
mise ls
mise ls-remote

mise install node@22.0.0
mise install node@22

mise uninstall node@22.0.0
mise uninstall node@22

mise use node@22
mise use -g node@22
```
