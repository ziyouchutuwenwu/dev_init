# 调用 c

## 说明

支持 c 和 cpp 混编

cpp 需要用 `extern "C"` 包装

## 例子

### 目录

```sh
.
src
├── libs
│   ├── c_lib
│   │   └── demo1
│   │       ├── demo1.c
│   │       ├── demo1.h
│   │       └── sub1
│   │           ├── sub1.c
│   │           └── sub1.h
│   └── cpp_lib
│       └── demo1
│           ├── demo1.cxx
│           ├── demo1.hpp
│           ├── sub1
│           │   ├── sub1.cpp
│           │   └── sub1.hpp
│           ├── wrapper.cpp
│           └── wrapper.hpp
├── main.zig
└── root.zig
```

### 代码

src/main.zig

```zig
const std = @import("std");
const c_lib = @cImport({
    @cInclude("libs/c_lib/demo1/demo1.h");
});
const cpp_lib = @cImport({
    @cInclude("libs/cpp_lib/demo1/wrapper.hpp");
});

pub fn main() !void {
    const c_sum = c_lib.demo1(11, 22);
    std.log.debug("c_sum {d}", .{c_sum});

    const cpp_calc = cpp_lib.calc(5, 7);
    std.log.debug("cpp_calc {d}", .{cpp_calc});
}
```

src/libs/c_lib/demo1/sub1/sub1.h

```h
#ifndef __SUB1_CINLUDED__
#define __SUB1_CINLUDED__

#include <stdio.h>

int sub1(int a, int b);

#endif
```

src/libs/c_lib/demo1/sub1/sub1.c

```c
#include "sub1.h"

int sub1(int a, int b) {
  return a + b;
}
```

src/libs/c_lib/demo1/demo1.h

```h
#ifndef __DEMO1_CINLUDED__
#define __DEMO1_CINLUDED__

#include <stdio.h>

int demo1(int a, int b);

#endif
```

src/libs/c_lib/demo1/demo1.c

```c
#include "demo1.h"
#include "./sub1/sub1.h"

int demo1(int a, int b) {
  return sub1(a, b);
}
```

src/libs/cpp_lib/demo1/sub1/sub1.hpp

```h
#ifndef SUB1_HPP_INCLUDED
#define SUB1_HPP_INCLUDED

#include <iostream>

class Sub1 {
public:
    Sub1();
    ~Sub1();

    int compute(int x, int y);

private:
    int factor;
};

#endif
```

src/libs/cpp_lib/demo1/sub1/sub1.cpp

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
#ifndef DEMO1_HPP_INCLUDED
#define DEMO1_HPP_INCLUDED

#ifdef __cplusplus
#include <iostream>

class Demo1 {
public:
    Demo1();
    ~Demo1();
    int calc(int a, int b);

private:
    int _value;
};
#endif

#endif
```

src/libs/cpp_lib/demo1/demo1.cxx

```cxx
#include "demo1.hpp"
#include "./sub1/sub1.hpp"

Demo1::Demo1() : _value(0) {
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

src/libs/cpp_lib/demo1/wrapper.hpp

```h
#ifndef WRAPPER_HPP_INCLUDED
#define WRAPPER_HPP_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

int calc(int a, int b);

#ifdef __cplusplus
}
#endif

#endif // WRAPPER_HPP_INCLUDED
```

src/libs/cpp_lib/demo1/wrapper.cpp

```cpp
#include "demo1.hpp"
#include "wrapper.hpp"

extern "C" int calc(int a, int b) {
    Demo1 demo;
    return demo.calc(a, b);
}
```

build.zig

```zig
fn find_c_cpp(build_ctx: *std.Build, dir: std.fs.Dir, base_path: []const u8, allocator: std.mem.Allocator, compile_step: *std.Build.Step.Compile) !void {
    const find = struct {
        fn inner(build_ctx_inner: *std.Build, dir_inner: std.fs.Dir, base_path_inner: []const u8, allocator_inner: std.mem.Allocator, compile_step_inner: *std.Build.Step.Compile) !void {
            var iter = dir_inner.iterate();
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
        }
    }.inner;

    try find(build_ctx, dir, base_path, allocator, compile_step);
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
const allocator = arena.allocator();

const libs_path = "src/libs";
var libs_dir = std.fs.cwd().openDir(libs_path, .{ .iterate = true }) catch |err| {
    std.debug.print("无法打开 {s} 目录: {}\n", .{libs_path, err});
    return;
};
defer libs_dir.close();

find_c_cpp(b, libs_dir, libs_path, allocator, exe) catch |err| {
    std.debug.print("查找 c/c++ 文件时出错: {}\n", .{err});
    return;
};

exe.addIncludePath(b.path("src"));
exe.linkSystemLibrary("c");
exe.linkSystemLibrary("stdc++");
```
