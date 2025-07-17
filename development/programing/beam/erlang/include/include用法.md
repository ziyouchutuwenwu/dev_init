# include 用法

## 例子

### include

从相对目录加载 hrl 文件

### include_lib

从系统目录加载 hrl 文件

```erlang
-include_lib("kernel/include/file.hrl").
```

kernel 的 base 目录

```erlang
code:lib_dir(kernel).
```

真实路径类似下面

```sh
/usr/lib64/erlang/lib/kernel-8.5/include/file.hrl
```
