# burrito

## 说明

依靠 zig，打包为无依赖的 exe

## 步骤

### 代码

mix.exs

```elixir
def releases do
  [
    aaa: [
      steps: [:assemble, &Burrito.wrap/1],
      burrito: [
        # 在当前平台上打三个平台的包
        targets: [
          linux: [os: :linux, cpu: :x86_64],
          macos: [os: :darwin, cpu: :x86_64],
          windows: [os: :windows, cpu: :x86_64]
        ]
      ]
    ]
  ]
end

def project do
[
  # ......
  releases: releases()
]
end

def application do
  [
    mod: {DemoApp, []},
    extra_applications: [:logger]
  ]
end

defp deps do
  [
    {:burrito, "~> 1.4.0"}
  ]
end
```

demo_app.ex

```elixir
defmodule DemoApp do
  use Application
  require Logger

  def start(_type, _args) do
    args = Burrito.Util.Args.argv()
    File.write("output.txt", "#{inspect(args)}")
    # System.halt(0)
    System.halt(1)
  end
end
```

### 编译

编译结果在 burrito_out 下

```sh
MIX_ENV=prod mix release
```

### 辅助

```sh
# 查看一些信息，比如 zig 的版本
xxx maintenance meta

# 查看解压路径
xxx maintenance directory

# 卸载
xxx maintenance uninstall
```
