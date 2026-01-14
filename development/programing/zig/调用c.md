# 调用 c

## 说明

支持 c 和 cpp 混编

cpp 需要用 `extern "C"` 包装

## 例子

### 结构

```sh
├── build.zig
├── build.zig.zon
├── libs
└── src
    ├── lib_wrapper
    │   ├── c_lib
    │   │   └── demo1
    │   │       ├── demo1.c
    │   │       ├── demo1.h
    │   │       └── sub1
    │   │           ├── sub1.c
    │   │           └── sub1.h
    │   └── cpp_lib
    │       └── demo1
    │           ├── demo1.cxx
    │           ├── demo1.hpp
    │           ├── sub1
    │           │   ├── sub1.cpp
    │           │   └── sub1.hpp
    │           ├── wrapper.cpp
    │           └── wrapper.hpp
    ├── main.zig
    └── root.zig
```

### 代码

main.zig

```zig
const std = @import("std");
const c_lib = @cImport({
    @cInclude("lib_wrapper/c_lib/demo1/demo1.h");
});
const cpp_lib = @cImport({
    @cInclude("lib_wrapper/cpp_lib/demo1/wrapper.hpp");
});

pub fn main() !void {
    const c_sum = c_lib.demo1(11, 22);
    std.log.debug("c_sum {d}", .{c_sum});

    const cpp_calc = cpp_lib.calc(5, 7);
    std.log.debug("cpp_calc {d}", .{cpp_calc});
}
```

src/lib_wrapper/c_lib/demo1/sub1/sub1.h

```h
#pragma once

#include <stdio.h>

int sub1(int a, int b);
```

src/lib_wrapper/c_lib/demo1/sub1/sub1.c

```c
#include "sub1.h"

int sub1(int a, int b) {
  return a + b;
}
```

src/lib_wrapper/c_lib/demo1/demo1.h

```h
#pragma once

#include <stdio.h>

int demo1(int a, int b);
```

src/lib_wrapper/c_lib/demo1/demo1.c

```c
#include "demo1.h"
#include "./sub1/sub1.h"

int demo1(int a, int b) {
  return sub1(a, b);
}
```

src/lib_wrapper/cpp_lib/demo1/sub1/sub1.hpp

```h
#pragma once

#include <iostream>

class Sub1 {
public:
    Sub1();
    ~Sub1();

    int compute(int x, int y);

private:
    int factor;
};
```

src/lib_wrapper/cpp_lib/demo1/sub1/sub1.cpp

```cpp
#include "sub1.hpp"

Sub1::Sub1() : factor(1) {
    std::cout << "sub1 构造" << std::endl;
}

Sub1::~Sub1() {
    std::cout << "sub1 析构" << std::endl;
}

int Sub1::compute(int x, int y) {
    return x * y + factor;
}
```

src/libs/cpp_lib/demo1/demo1.hpp

```h
#pragma once

#include <iostream>

class Demo1 {
public:
    Demo1();
    ~Demo1();
    int calc(int a, int b);
};
```

src/libs/cpp_lib/demo1/demo1.cxx

```cxx
#include "demo1.hpp"
#include "./sub1/sub1.hpp"

Demo1::Demo1(){
    std::cout << "demo1 构造" << std::endl;
}

Demo1::~Demo1() {
    std::cout << "demo1 析构" << std::endl;
}

int Demo1::calc(int a, int b) {
    Sub1 sub;
    return sub.compute(a, b);
}
```

src/lib_wrapper/cpp_lib/demo1/wrapper.hpp

```h
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

int calc(int a, int b);

#ifdef __cplusplus
}
#endif
```

src/lib_wrapper/cpp_lib/demo1/wrapper.cpp

```cpp
#include "demo1.hpp"
#include "wrapper.hpp"

extern "C" int calc(int a, int b) {
    Demo1 demo;
    return demo.calc(a, b);
}
```

### 构建

build.zig

```zig
// 递归搜索目录，自动 addCSourceFile 和 addIncludePath
fn find_c_cpp(build_ctx: *std.Build, dir: std.fs.Dir, base_path: []const u8, allocator: std.mem.Allocator, compile_step: *std.Build.Step.Compile) !void {
    const find = struct {
        fn inner(build_ctx_inner: *std.Build, dir_inner: std.fs.Dir, base_path_inner: []const u8, allocator_inner: std.mem.Allocator, compile_step_inner: *std.Build.Step.Compile) !void {
            var iter = dir_inner.iterate();
            var has_header_files = false;

            while (try iter.next()) |entry| {
                const full_path = try std.fs.path.join(allocator_inner, &.{ base_path_inner, entry.name });
                defer allocator_inner.free(full_path);

                switch (entry.kind) {
                    .file => {
                        if (std.mem.endsWith(u8, entry.name, ".c")) {
                            compile_step_inner.addCSourceFile(.{
                                .file = build_ctx_inner.path(full_path),
                                .flags = &.{"-std=c99"},
                            });
                        } else if (std.mem.endsWith(u8, entry.name, ".cpp") or std.mem.endsWith(u8, entry.name, ".cxx")) {
                            compile_step_inner.addCSourceFile(.{
                                .file = build_ctx_inner.path(full_path),
                                .flags = &.{"-std=c++11"},
                            });
                        } else if (std.mem.endsWith(u8, entry.name, ".h") or std.mem.endsWith(u8, entry.name, ".hpp")) {
                            has_header_files = true;
                        }
                    },
                    .directory => {
                        var sub_dir = try dir_inner.openDir(entry.name, .{ .iterate = true });
                        defer sub_dir.close();
                        try inner(build_ctx_inner, sub_dir, full_path, allocator_inner, compile_step_inner);
                    },
                    else => {},
                }
            }

            if (has_header_files) {
                compile_step_inner.addIncludePath(build_ctx_inner.path(base_path_inner));
            }
        }
    }.inner;

    try find(build_ctx, dir, base_path, allocator, compile_step);
}
```

```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
const allocator = arena.allocator();

const process_dir = struct {
    fn process(build_ctx: *std.Build, path: []const u8, alloc: std.mem.Allocator, compile_step: *std.Build.Step.Compile) void {
        var dir = std.fs.cwd().openDir(path, .{ .iterate = true }) catch |err| {
            std.debug.print("无法打开 {s} 目录: {}\n", .{path, err});
            return;
        };
        defer dir.close();

        find_c_cpp(build_ctx, dir, path, alloc, compile_step) catch |err| {
            std.debug.print("在 {s} 目录中查找 c/c++ 文件时出错: {}\n", .{path, err});
            return;
        };
    }
}.process;

process_dir(b, "libs", allocator, exe);
process_dir(b, "src/lib_wrapper", allocator, exe);

exe.addIncludePath(b.path("src"));
exe.linkSystemLibrary("c");
exe.linkSystemLibrary("stdc++");
```