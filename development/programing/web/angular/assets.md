# assets

## 位置

angular.json

```json
"assets": [
  {
    "glob": "**/*",
    "input": "public"
  }
]
```

对应的目录结构

```sh
public
├── assets
```

## 引用

html 引用

```html
<img src="/assets/aa.png" />
```

css 引用

```css
background-image: url("/assets/bg.jpg");
```
