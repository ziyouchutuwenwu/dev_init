# apply

## 说明

给属性起别名

## 例子

```css
@import "tailwindcss";

@utility center-grid {
  @apply flex justify-center items-center;
}
```

```html
<div class="bg-red-200 h-120 center-grid">
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
