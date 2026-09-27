# assets

## 说明

mix.exs

```elixir
defp aliases do
  [
    ......
    # 下载 tailwindcss 和 esbuild
    "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
    ......

    # 为编译后，加上指纹，防止页面的缓存问题
    "assets.deploy": [
      # 清理之前的 digest
      "phx.digest.clean --all",

      "tailwind web_demo --minify",
      "esbuild web_demo --minify",

      "phx.digest"
    ]
  ]
end
```

## 用法

npm

```sh
# 不是 priv/static/assets
cd assets
npm install xxx --prefix assets
```

页面引用

```html
<img src={~p"/images/mouse.png"}/>
```

发布

```sh
MIX_ENV=prod mix assets.deploy
```

指定目录

```sh
mix assets.deploy priv/static -o /www/public
```

endpoint.ex

```elixir
plug Plug.Static,
  at: "/",
  # from: :web_demo,
  from: "/www/public",
  gzip: false,
  only: WebDemoWeb.static_paths()
```
