# css

## 说明

不支持单独的 css 文件在 heex 里面引用, 建议加上相关前缀的 class 来区分

## 例子

创建 css

```sh
assets/css/demo/aaa.css
```

app.css

```css
@import "demo/aaa.css";
```
