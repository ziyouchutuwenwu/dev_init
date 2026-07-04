# tcp

## 说明

粘包处理

## 配置

默认两字节包头

```sh
data, err := conn.RecvPkg()
```

自定义包头长度

```sh
option := gtcp.PkgOption{HeaderSize: 4}
data, err := conn.RecvPkg(option)
```
