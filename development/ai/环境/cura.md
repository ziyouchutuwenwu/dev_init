# cura

## 说明

管理 cuda 版本

## 步骤

安装

```sh
curl --proto '=https' --tlsv1.2 -fsSL 'https://github.com/mindify-ai/cura-cli/blob/main/install.sh?raw=1' | sh
```

shell 注册

```sh
# zsh
eval "$(cura shell init zsh)"

# bash
eval "$(cura shell init bash)"
```

用法

```sh
cura install 12.4
cura use 12.4
cura removee 12.4
```
