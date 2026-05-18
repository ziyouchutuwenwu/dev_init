# phoenix

## 说明

nerves 项目为主项目

phoenix 打包到 nerves 里面

## 配置

```sh
mix phx.new my_web --no-ecto
```

### 准备

```sh
export MIX_TARGET=x86_64
export MIX_ENV=prod
```

### 依赖

主项目的 mix.exs

```elixir
defp deps do
  [
    {:my_web, path: "../my_web", targets: @all_targets},
     # 这个依赖需要手动添加，否则启动失败
    {:hackney, "~> 1.20", targets: @all_targets},
    ...
  ]
end
```

### 开机启动

主项目

config/target.exs

```elixir
config :my_web, MyWebWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  server: true,
  force_ssl: false,
  check_origin: true,
  secret_key_base:
    :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false) |> binary_part(0, 64)
```

### phx 配置

phoenix 项目内

```bash
mix compile
# assets 需要先 compile
mix assets.deploy
```

### 测试

nerves 项目里

````sh
mix firmware

# dev
fwup -d disk.img _build/x86_64_dev/nerves/images/nerves_demo.fw -y
# prod
fwup -d disk.img _build/x86_64_prod/nerves/images/nerves_demo.fw -y

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 1024 \
  -drive file=disk.img,if=virtio,format=raw \
  -netdev bridge,id=net0,br=virbr0 \
  -device virtio-net-pci,netdev=net0 \
  -nographic \
  -serial mon:stdio
````

### 检测

```sh
Application.get_env(:my_web, MyWebWeb.Endpoint)
```
