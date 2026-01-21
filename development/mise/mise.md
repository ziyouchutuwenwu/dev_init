# mise

## 说明

多版本管理工具，支持多种后端，自动选择，更好用

## 安装

官网

```sh
https://github.com/jdx/mise
```

安装

```sh
curl https://mise.run | sh
```

~/.profile

```sh
# bash
eval "$(mise activate bash)"

# zsh
eval "$(mise activate zsh)"
```

所在路径

```sh
$HOME/.local/bin/mise
$HOME/.config/mise/
$HOME/.local/share/mise/
$HOME/.local/state/mise/
```

## 用法

搜索

```sh
mise search xxx
mise ls

# 可以看 tag
mise ls-remote node
```

安装并且写入 toml

```sh
# 最新版
mise use -g uv

# 指定版本
mise use node@22
mise use -g node@lts

# toml 里面删除
mise unuse node@22
```

安装卸载

```sh
mise install node@22
mise uninstall node@22
```

更新

```sh
mise self-update
```
