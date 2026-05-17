# tailwindcss

## 配置

```sh
手动下载 phoenix 提供的版本
npm 的版本有问题
```

config/config.exs

```elixir
config :tailwind,
  version_check: false,
  path: System.find_executable("tailwind"),


config :esbuild,
  version_check: false,
  path: System.find_executable("esbuild"),
```
