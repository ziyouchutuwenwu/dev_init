# assets

## 目录说明

有两个 assets 目录

- assets
  这里的 css 和 js 是用 imort 的模式
  发布时需要先编译，然后会自动复制到 priv 下的 assets 目录里面
  发布以后，只有一个 app.js 和 app.css 会被默认引用

- priv/static/assets/
  最终引用的 css 和 js 在这个地方
  如果需要使用传统方式，在页面引入其它 css 和 js，则放在这里

- 图片
  在执行编译命令以后，图片也会生成一份随机数文件
  图片默认在 priv/static/images/
  放在 priv/static/assets 也可以引用到

## 手动引入

```html
<!-- 这是用来引入 priv/static/assets/ 里面的东西的 -->
<script src="/assets/aaa/aa.js"></script>

<!-- assets 和 images 目录都可以 -->
<!-- <img src={~p"/images/mouse.png"}/> -->
<img src={~p"/assets/mouse.png"}/>
```

## 编译命令

- tailwind 用来压缩 css
- esbuild 用来打包 app.js
- digest 用来生成指纹

```elixir
"assets.deploy": [
  "tailwind web_demo --minify",
  "esbuild web_demo --minify",
  "phx.digest"
]
```

用法

```sh
# 压缩，priv/static/ 内生成带随机数的文件名，随机数文件用于生产模式下加载
MIX_ENV=prod mix assets.deploy

# 清理 priv/static 目录
mix phx.digest.clean --all
```

指定输出目录

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
