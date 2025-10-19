# vscodium

## 插件市场

```sh
~/.config/VSCodium/product.json
```

```json
{
  "extensionsGallery": {
    "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
    "itemUrl": "https://marketplace.visualstudio.com/items",
    "controlUrl": ""
  }
}
```

## 同步

要先指定要 json 的路径

```sh
touch ~/.config/VSCodium/User/settings.json
touch ~/.config/VSCodium/User/keybindings.json
```

```sh
ext install DunderDev.sync-everything
```
