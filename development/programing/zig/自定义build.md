# 自定义 build

## 说明

一般用来生成无任何依赖的 bin

## 例子

```zig
const default_target = std.Target.Query{
    // .cpu_arch = std.Target.Cpu.Arch.x86_64,
    // .os_tag = std.Target.Os.Tag.linux,
    .abi = std.Target.Abi.musl,
};
const target = b.standardTargetOptions(.{
    .default_target = default_target,
});
```
