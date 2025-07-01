# css

## 用法

### 全局

angular.json

```json
// 配置这个以后，index.html 里面，直接的 style 指令会变为 link 的 css 文件
"optimization": {
  "styles": {
    "inlineCritical": false
  }
},

// 配置以后可以直接 import
// css 不支持，sass scss less 支持
"stylePreprocessorOptions": {
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
