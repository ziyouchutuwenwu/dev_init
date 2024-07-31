# 调用 c

## 例子

### 目录

```sh
.
├── build.zig
└── src
    ├── main.zig
    └── xx
        ├── demo.c
        └── demo.h
```

### 代码

src/main.zig

```zig
const std = @import("std");
const clib = @cImport({
    @cInclude("xx/demo.h");
});

pub fn main() !void {
    const sum = clib.add(11, 22);
    std.debug.print("sum {d}\n", .{sum});
}
```

src/xx/demo.h

```hpp
#ifndef __DEMO_CINLUDED__
#define __DEMO_CINLUDED__

#include <stdio.h>

int add(int a, int b);

#endif
```

src/xx/demo.c

```c
#include "demo.h"

int add(int a, int b) {
  return a + b;
}
```

build.zig

```zig
// 增加 c 库
const Build = std.build;
exe.addCSourceFile(.{
    .file = Build.LazyPath.relative("src/xx/demo.c"),
    .flags = &[_][]const u8{"-std=c99"},
});
exe.addIncludePath(Build.LazyPath.relative("src"));
exe.linkSystemLibrary("c");
```
