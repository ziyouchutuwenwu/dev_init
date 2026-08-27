# include 用法

## 例子

### include

从相对目录加载 hrl 文件

```erlang
% 相对路径
-include("include/file.hrl").
```

### include_lib

从系统目录加载 hrl 文件

```erlang
% code:lib_dir(kernel).
-include_lib("kernel/include/file.hrl").
```

真实路径类似下面

```sh
/usr/lib64/erlang/lib/kernel-8.5/include/file.hrl
```
