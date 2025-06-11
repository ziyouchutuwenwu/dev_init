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
if [[ "$TERM_PROGRAM" == "vscode" && "$CHROME_DESKTOP" == "cursor.desktop" && -z "$CURSOR_INITED" ]]; then
    # echo "cursor shell"
    export CURSOR_INITED=1
    sh -c $SHELL
else
    # 系统 shell
    eval "$(mise activate zsh)"
fi
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
mise search xxx
mise ls-remote node
mise ls

mise install node@22.0.0
mise install node@22

mise uninstall node@22.0.0
mise uninstall node@22

# 写入到 toml
mise use node@22
mise use -g node@22

# 从 toml 里面删除
mise unuse node@22
```
