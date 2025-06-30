# css

## 说明

凡是全局启用的，编译以后会注入到 index.html 的 style 指令里面, chrome 插件不支持

## 用法

### 全局

angular.json 里面添加到 styles

```json
"styles": [
  "src/styles.css",
  "mycss/aaa.css"
]
```

### 自定义

需要的时候

```css
@import "../mycss/aaa.css";
```
