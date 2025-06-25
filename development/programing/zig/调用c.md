# 调用 c

## 例子

### 目录

```sh
.
├── build.zig
├── build.zig.zon
└── src
    ├── c_lib
    │   ├── demo
    │   │   ├── demo.c
    │   │   └── demo.h
    │   └── sub
    │       ├── sub.c
    │       └── sub.h
    ├── main.zig
    └── root.zig
```

### 代码

src/main.zig

```zig
const std = @import("std");
const clib = @cImport({
    @cInclude("c_lib/demo/demo.h");
});

pub fn main() !void {
    const sum = clib.demo(11, 22);
    std.log.debug("sum {d}", .{sum});
}
```

src/c_lib/sub/sub.h

```h
#ifndef __SUB_CINLUDED__
#define __SUB_CINLUDED__

#include <stdio.h>

int sub(int a, int b);

#endif
```

src/c_lib/sub/sub.c

```c
#include "sub.h"

int sub(int a, int b) {
  return a + b;
}
```

src/c_lib/demo/demo.h

```h
#ifndef __DEMO_CINLUDED__
#define __DEMO_CINLUDED__

#include <stdio.h>

int demo(int a, int b);

#endif
```

src/c_lib/demo/demo.c

```c
#include "demo.h"
#include "../sub/sub.h"

int demo(int a, int b) {
  return sub(a, b);
}
```

build.zig

```zig
exe.addCSourceFile(.{ .file = b.path("src/c_lib/demo/demo.c"), .flags = &.{"-std=c99"} });
exe.addCSourceFile(.{ .file = b.path("src/c_lib/sub/sub.c"), .flags = &.{"-std=c99"} });
exe.addIncludePath(b.path("src"));
exe.linkSystemLibrary("c");
```
