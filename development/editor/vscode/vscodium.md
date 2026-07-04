# vscodium

## 说明

自带的插件市场没有 vscode 的完善

## 配置

使用 vscode 的扩展市场

### 环境变量

```sh
export VSCODE_GALLERY_SERVICE_URL="https://marketplace.visualstudio.com/_apis/public/gallery"
export VSCODE_GALLERY_ITEM_URL="https://marketplace.visualstudio.com/items"
export VSCODE_GALLERY_LATEST_URL_TEMPLATE="https://www.vscode-unpkg.net/_gallery/{publisher}/{name}/latest"
```

### 配置文件

~/.config/VSCodium/product.json

```json
{
  "extensionsGallery": {
    "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
    "itemUrl": "https://marketplace.visualstudio.com/items",
    "latestUrlTemplate": "https://www.vscode-unpkg.net/_gallery/{publisher}/{name}/latest"
  }
}
```

测试

```sh
code --install-extension bwildeman.tabulous --verbose
```
