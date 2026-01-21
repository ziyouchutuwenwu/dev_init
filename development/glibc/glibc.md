# glibc

## 用法

### 查看当前版本

```sh
ldd --version
```

```sh
strings /lib/libc.so.6 | grep "release version"
```

### 查看实际 glibc 路径

```sh
ll /lib/libc.so.*
ldconfig -p | grep libc.so
```

### 查看所有兼容版本

```sh
strings /lib/libc.so.6 | grep GLIBC
```
