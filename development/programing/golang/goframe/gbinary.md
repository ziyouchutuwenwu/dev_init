# gbinary

用于 socket 通信的时候的编解码

## 例子

```golang
data := make([]byte, 0)
cmd := gbinary.BeEncodeUint16(111)
data = append(data, cmd...)
data = append(data, []byte("这是服务器发的测试数据")...)
conn.SendPkg(data, gtcp.PkgOption{HeaderSize: 2})
```
