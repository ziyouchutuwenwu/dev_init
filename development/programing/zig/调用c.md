# 调用c

## 说明

把 C 源码和头文件加入到 Zig 项目中一起编译

zig 通过 `extern fn` 声明 c 函数。

## 例子

目录结构

```sh
├── build.zig
├── build.zig.zon
├── csrc
│   ├── demo.h
│   └── demo.c
└── src
    └── main.zig
```

csrc/demo.h

```c
#pragma once

int demo(void);
```

csrc/demo.c

```c
#include "demo.h"
#include <stdio.h>

int demo(void) {
    printf("demo from c\n");
    return 42;
}
```

src/main.zig

```zig
const std = @import("std");

extern fn demo() i32;

pub fn main() !void {
    const result = demo();
    std.debug.print("demo returned: {}\n", .{result});
}
```

build.zig

```zig
exe.root_module.addCSourceFile(.{
    .file = b.path("csrc/demo.c"),
    .flags = &.{"-std=c99"},
});
exe.root_module.addIncludePath(b.path("csrc"));
exe.root_module.linkSystemLibrary("c", .{});
```

运行

```sh
zig build run
```
