# css

## 说明

凡是全局启用的，编译以后会注入到 index.html 的 style 指令里面, chrome 插件不支持

## 用法

### 全局

angular.json

```json
"stylePreprocessorOptions": {
  // 配置以后可以直接 import
  "includePaths": ["src", "mycss"]
},
// 自动全局加载
"styles": [
  "src/styles.scss",
  "mycss/aaa.scss"
]
```

### 手动

不需要配置

```css
@import "../mycss/aaa.scss";
@import "../mycss/aaa";
```
