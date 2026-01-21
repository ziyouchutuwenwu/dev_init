# assets

## 说明

endpoint 里面，定义 static_paths

```sh
priv/static/
  assets/      # 编译后的 JS/CSS 等（由 esbuild 等工具生成）
  fonts/       # 字体文件
  images/      # 图片文件
  favicon.ico  # 网站图标
  robots.txt   # 搜索引擎爬虫协议文件
```

## 用法

### 安装

在 assets 目录下生成 package.json

```sh
npm install xxx --prefix assets
```

### 页面

```html
<img src={~p"/images/mouse.png"}/>
```

### 编译

```sh
MIX_ENV=prod mix assets.deploy
mix phx.digest.clean --all
```

### 指定目录

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
