# profile

## 说明

zsh 加载 profile 需要模拟

## 用法

linux 下

```sh
/etc/zsh/zshenv
```

freebsd 下

```sh
/usr/local/etc/zshenv
```

内容

```sh
emulate sh -c 'source /etc/profile'
```
