# apply

## 说明

给属性起别名

## 例子

flex.css

```css
@import "tailwindcss";

/* main */
@utility main-align-start {
  @apply justify-start;
}
@utility main-align-center {
  @apply justify-center;
}
@utility main-align-end {
  @apply justify-end;
}
@utility main-align-between {
  @apply justify-between;
}
@utility main-align-around {
  @apply justify-around;
}
@utility main-align-evenly {
  @apply justify-evenly;
}

/* cross */
@utility cross-align-start {
  @apply items-start;
}
@utility cross-align-center {
  @apply items-center;
}
@utility cross-align-end {
  @apply items-end;
}
@utility cross-align-baseline {
  @apply items-baseline;
}
@utility cross-align-stretch {
  @apply items-stretch;
}
```

grid.css

```css
@import "tailwindcss";

/* horizon */
@utility horizon-align-start {
  @apply justify-items-start;
}
@utility horizon-align-center {
  @apply justify-items-center;
}
@utility horizon-align-end {
  @apply justify-items-end;
}
@utility horizon-align-stretch {
  @apply justify-items-stretch;
}

/* vertical */
@utility vertical-align-start {
  @apply items-start;
}
@utility vertical-align-center {
  @apply items-center;
}
@utility vertical-align-end {
  @apply items-end;
}
@utility vertical-align-stretch {
  @apply items-stretch;
}

/* both */
@utility align-both-start {
  @apply place-items-start;
}
@utility align-both-center {
  @apply place-items-center;
}
@utility align-both-end {
  @apply place-items-end;
}
@utility align-both-stretch {
  @apply place-items-stretch;
}
```

```html
<div class="flex bg-red-200 h-120 main-align-center cross-align-center">
  <div class="grid grid-cols-3 gap-4 bg-gray-100 p-4">
    <div class="bg-blue-500 text-white w-32 h-32">元素 1</div>
    <div class="bg-green-500 text-white w-32 h-32">元素 2</div>
    <div class="bg-red-500 text-white w-32 h-32">元素 3</div>
    <div class="bg-blue-500 text-white w-32 h-32">元素 4</div>
    <div class="bg-green-500 text-white w-32 h-32">元素 5</div>
    <div class="bg-red-500 text-white w-32 h-32">元素 6</div>
  </div>
</div>
```
