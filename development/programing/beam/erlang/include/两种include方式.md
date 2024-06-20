# 两种 include 方式

## 区别

### include_lib

从系统目录加载 hrl 文件

#### 例子

真实路径

```sh
/usr/lib64/erlang/lib/kernel-8.5/include/file.hrl
```

查看 kernel 模块 对应路径

```erlang
code:lib_dir(kernel).
```

写法

```erlang
-include_lib("kernel/include/file.hrl").
```

### include

从相对目录加载 hrl 文件
