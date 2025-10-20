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

复制相关的 json

```sh
~/.config/Code/User/settings.json
~/.config/Code/User/keybindings.json
```

插件

```sh
# 备份
code --list-extensions > extensions.txt

cat extensions.txt | xargs -L 1 code --install-extension
cat extensions.txt | xargs -L 1 code --uninstall-extension
```
