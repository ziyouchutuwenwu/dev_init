# vfox

## 配置

```sh
eval "$(vfox activate zsh)"
```

## 用法

### 插件用法

查看所有语言

```sh
vfox available
```

```sh
vfox add erlang
vfox remove elixir
```

### 基础用法

查看所有版本

```sh
vfox search python
```

```sh
vfox install python@3.10.17
vfox uninstall python@3.10.17

# latest
vfox install nodejs@latest
```

查看本地所有

```sh
vfox list
```

```sh
# 全局
vfox use -g python@3.10.17

# 当前目录
vfox use -p python@3.10.17

# 当前 session
vfox use -s python@3.10.17
```
