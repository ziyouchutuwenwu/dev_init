# dom 解析

## 例子

解析如下 dom

```html
<div class="cell--B7yKd" style="padding-top: 178.475%">
  <div class="container--MwyXl">
    <a class="link--WHWzm" href="/zh/photos/trees-woods-forest-8274904/" data-id="8274904"
      ><img
        src="https://cdn.pixabay.com/photo/2023/09/25/12/49/trees-8274904_640.jpg"
        srcset="
          https://cdn.pixabay.com/photo/2023/09/25/12/49/trees-8274904_640.jpg  1x,
          https://cdn.pixabay.com/photo/2023/09/25/12/49/trees-8274904_1280.jpg 2x
        "
        alt="树木, 森林, 苔藓, 多雾路段, 秋天, 环境, 落下, 生长, 薄雾, 自然"
        style="max-width: 2295px; max-height: 4096px"
    /></a>
  </div>
</div>
```

```elixir
Floki.find(doc, "*[class^='cell--'] img")
```
