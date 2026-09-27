# tailwindcss

## 步骤

配置

```sh
手动下载 phoenix 提供的版本
npm 的版本有问题
```

config/config.exs

```elixir
config :tailwind,
  version_check: false,
  path: System.find_executable("tailwindcss"),


config :esbuild,
  version_check: false,
  path: System.find_executable("esbuild"),
```

下载

```sh
# mix.exs 里面
mix assets.setup
```
