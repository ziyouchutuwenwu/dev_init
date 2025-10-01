# grid

## 说明

- 父元素 justify-items-xxx → 控制子元素水平

- 父元素 items-xxx → 控制子元素垂直

- 父元素 place-items-xxx → 同时控制子元素水平和垂直

- 父元素 gap-xxx → 控制行列间距

## 例子

水平居中

```html
<div class="grid grid-cols-3 gap-4 justify-items-center bg-gray-100 h-80 p-4">
  <div class="bg-blue-500 text-white w-16 h-8">A</div>
  <div class="bg-green-500 text-white w-24 h-12">B</div>
  <div class="bg-red-500 text-white w-20 h-10">C</div>
  <div class="bg-blue-500 text-white w-16 h-8">AA</div>
  <div class="bg-green-500 text-white w-24 h-12">BB</div>
  <div class="bg-red-500 text-white w-20 h-10">CC</div>
</div>
```

垂直居中

```html
<div class="grid grid-cols-3 gap-4 items-center bg-gray-100 h-80 p-4">
  <div class="bg-blue-500 text-white w-16 h-8">A</div>
  <div class="bg-green-500 text-white w-24 h-12">B</div>
  <div class="bg-red-500 text-white w-20 h-10">C</div>
  <div class="bg-blue-500 text-white w-16 h-8">AA</div>
  <div class="bg-green-500 text-white w-24 h-12">BB</div>
  <div class="bg-red-500 text-white w-20 h-10">CC</div>
</div>
```

水平垂直同时居中

```html
<div class="grid grid-cols-3 gap-4 place-items-center bg-gray-100 h-80 p-4">
  <div class="bg-blue-500 text-white w-16 h-8">A</div>
  <div class="bg-green-500 text-white w-24 h-12">B</div>
  <div class="bg-red-500 text-white w-20 h-10">C</div>
  <div class="bg-blue-500 text-white w-16 h-8">AA</div>
  <div class="bg-green-500 text-white w-24 h-12">BB</div>
  <div class="bg-red-500 text-white w-20 h-10">CC</div>
</div>
```
