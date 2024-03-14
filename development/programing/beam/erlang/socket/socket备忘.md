# socket 备忘

[参考地址](http://blog.csdn.net/mycwq/article/details/18359007)

## socket 选项

```sh
{packet, 2}     erlang处理2字节大端包头
{packet, 4}     erlang处理4字节大端包头
{packet, 0}     erlang不负责拆包，用户自己处理
{packet, raw}   erlang不负责拆包，用户自己处理，和 {packet, 0} 的区别应该在于 raw socket 可以处理 icmp 之类的特殊包
{active, true}  创建一个主动套字节(非阻塞)
{active, false} 创建一个被动套字节(阻塞),如果为false表必须手工处理阻塞, 否则阻塞在此处无法收听, 当前我无法处理
{active, once}  创建一个一次性被动套字节(阻塞),只收听一次后堵塞，必须调用 inet:setopts(Socket, [{active, once}]), 后才可收听下一条
```

## 粘包处理

例子在 [这里](https://github.com/kqqsysu/ssdb-erlang/blob/master/src/ssdb_conn.erl)

看 `handle_info({tcp,Socket,Data}` 部分