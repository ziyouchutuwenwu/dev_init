# assets

## 说明

assets 包含 js 和 css，不含图片

根目录下 assets 目录为存放 js 和 css 的目录

## 压缩

### 命令

tailwind 用来压缩 css

esbuild 用来打包 app.js

digest 用来生成指纹

```elixir
"assets.deploy": [
  "tailwind web_demo --minify",
  "esbuild web_demo --minify",
  "phx.digest"
]
```

### 流程

digest 以后，assets 目录的 js 和 css 会被编译到 priv/static/assets 目录下, 会生成一串带有随机数名字的文件

同时，priv/static/images 内的图片也会另外生成一份带有随机数名的图片

这两者生成的带随机数的文件均用于生产模式下加载

### 用法

```sh
# 压缩
MIX_ENV=prod mix assets.deploy

# 指定目录
mix assets.deploy priv/static -o ~/downloads/aaa

# 清理 priv/static 目录
mix phx.digest.clean --all
```
