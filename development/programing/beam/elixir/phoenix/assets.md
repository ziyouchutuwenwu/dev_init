# assets

## 概念

assets 包含 js 和 css

图片不算 assets

## 说明

根目录下 assets 目录为存放 js 和 css 的目录

### digest

在生产环境下，digest 以后，assets 目录的 js 和 css 会被编译到 priv/static/assets 目录下, 会生成一串带有随机数名字的文件，生产模式下，加载这种带随机数名字的文件

同时，priv/static/images 内的图片也会另外生成一份带有随机数名的图片，生产模式下，加载这种带随机数名字的图片

```sh
MIX_ENV=prod mix assets.deploy
```

### clean

清理 priv/static 目录

```sh
mix phx.digest.clean --all
```

## 图片引用

```html
<img src={~p"/images/sarah-dayan.jpg"} alt="" width="384" height="512" />
```
