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
    {:hackney, "~> 1.20", targets: @all_targets}
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
  secret_key_base: System.get_env("SECRET_KEY_BASE")
```

或者

```elixir
config :my_web, MyWebWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  server: true,
  force_ssl: false,
  check_origin: true
```

runtime.exs

```elixir
import Config

data_dir = "/data"
secret_file = Path.join(data_dir, "phoenix_secret_key_base")

secret_key =
  if File.exists?(secret_file) do
    File.read!(secret_file) |> String.trim()
  else
    key = :crypto.strong_rand_bytes(64) |> Base.encode16(case: :lower)

    if File.dir?(data_dir) do
      try do
        File.write!(secret_file, key)
      rescue
        _error ->
          IO.puts("/data 分区只读，无法写入密钥")
          key
      end
    end

    key
  end

config :my_web, MyWebWeb.Endpoint, secret_key_base: secret_key
```

### phx 配置

phoenix 项目内

```bash
mix compile

# 如果 secret_key 是自己动态生成，则不需要这个
# 需要先 compile，否则 SECRET_KEY_BASE 会带编译信息
export SECRET_KEY_BASE=`mix phx.gen.secret`

# assets 需要先 compile
mix assets.deploy
```

### 测试

nerves 项目里

````sh
mix firmware

# dev
fwup -d disk.img _build/x86_64_dev/nerves/images/demo.fw -y
# prod
fwup -d disk.img _build/x86_64_prod/nerves/images/demo.fw -y

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 1024 \
  -drive file=disk.img,if=virtio,format=raw \
  -net nic,model=virtio \
  -net user,hostfwd=tcp::4000-:4000,hostfwd=tcp::10022-:22 \
  -nographic \
  -serial mon:stdio
````

### 检测

```sh
Application.get_env(:my_web, MyWebWeb.Endpoint)[:server]
Application.get_env(:my_web, MyWebWeb.Endpoint)
```
