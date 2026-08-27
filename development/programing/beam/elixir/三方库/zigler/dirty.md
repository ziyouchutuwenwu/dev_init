# dirty

## 说明

dirty_cpu, cpu 密集
dirty_io, io 密集型

不支持在一个方法上打两个标签

```elixir
# 这种不支持
ccc: [:dirty_cpu, :dirty_io]
```

## 例子

xxx.zig

```zig
const std = @import("std");
const linux = std.os.linux;

// cpu 密集
pub fn aaa(n: u64) u64 {
    var sum: u64 = 0;
    var i: u64 = 0;
    while (i < n) : (i += 1) {
        if (i % 7 == 0) sum += i;
    }
    return sum;
}

// io 密集
pub fn bbb(ms: u64) void {
    const ts = linux.timespec{
        .sec = @intCast(ms / 1000),
        .nsec = @intCast((ms % 1000) * std.time.ns_per_ms),
    };
    _ = linux.nanosleep(&ts, null);
}
```

lib/demo_zig.ex

```elixir
defmodule DemoZig do
  use Zig,
    ......
    nifs: [
      aaa: [:dirty_cpu],
      bbb: [:dirty_io]
    ]

  ~Z"""
  pub fn aaa(n: u64) u64 {
    return xxx.aaa(n);
  }

  pub fn bbb(ms: u64) void {
    xxx.bbb(ms);
  }
  """
end
```

```elixir
defmodule Demo do
  require Logger

  def demo do
    # 1. dirty_cpu — 跑在 dirty cpu 线程上，普通调度器可以继续调度别人
    Logger.info("aaa start")
    spawn(fn -> Logger.info("aaa result: #{DemoZig.aaa(100_000_000)}") end)
    Process.sleep(10)
    Logger.info("可以并发处理其它事情")  # 这个能立刻打印出来
    Process.sleep(2000)

    # 2. dirty_io — 跑在 dirty io 线程上，用于阻塞型 io (sleep、网络、文件)
    Logger.info("bbb start")
    spawn(fn -> DemoZig.bbb(500); Logger.info("bbb done") end)
    Process.sleep(10)
    Logger.info("也可以并发处理其它事情")
    Process.sleep(600)
  end
end
```
