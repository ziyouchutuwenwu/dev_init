# vscodium

## 插件市场

gui 模式有效，cli 安装无效

```sh
~/.config/VSCodium/product.json
```

```json
{
  "extensionsGallery": {
    "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
    "itemUrl": "https://marketplace.visualstudio.com/items"
  }
}
```

cli 安装要修改自带的 product.json

```sh
resources/app/product.json
```

```json
"extensionsGallery": {
  "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
  "itemUrl": "https://marketplace.visualstudio.com/items"
},
```

测试

```sh
code --install-extension bwildeman.tabulous
```

## 插件同步

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

中文

```sh
Configure Display Language
```
