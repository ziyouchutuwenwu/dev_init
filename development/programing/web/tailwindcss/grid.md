# grid

## 说明

grid 外层，包一个 flex，兼容性最好

## 用法

### 设置对齐

- 父元素 justify-items-xxx → 控制子元素水平

- 父元素 items-xxx → 控制子元素垂直

- 父元素 place-items-xxx → 同时控制子元素水平和垂直

- 父元素 gap-xxx → 控制子元素的行和列的间距

水平居中

```html
<div class="grid grid-cols-3 gap-4 justify-items-center bg-gray-100 h-80 p-4">
  <div class="bg-blue-500 text-white w-16 h-8">元素 1</div>
  <div class="bg-green-500 text-white w-24 h-12">元素 2</div>
  <div class="bg-red-500 text-white w-20 h-10">元素 3</div>
  <div class="bg-blue-500 text-white w-16 h-8">元素 4</div>
  <div class="bg-green-500 text-white w-24 h-12">元素 5</div>
  <div class="bg-red-500 text-white w-20 h-10">元素 6</div>
</div>
```

垂直居中

```html
<div class="grid grid-cols-3 gap-4 items-center bg-gray-100 h-80 p-4">
  <div class="bg-blue-500 text-white w-16 h-8">元素 1</div>
  <div class="bg-green-500 text-white w-24 h-12">元素 2</div>
  <div class="bg-red-500 text-white w-20 h-10">元素 3</div>
  <div class="bg-blue-500 text-white w-16 h-8">元素 4</div>
  <div class="bg-green-500 text-white w-24 h-12">元素 5</div>
  <div class="bg-red-500 text-white w-20 h-10">元素 6</div>
</div>
```

水平垂直同时居中

```html
<div class="grid grid-cols-3 gap-4 place-items-center bg-gray-100 h-80 p-4">
  <div class="bg-blue-500 text-white w-16 h-8">元素 1</div>
  <div class="bg-green-500 text-white w-24 h-12">元素 2</div>
  <div class="bg-red-500 text-white w-20 h-10">元素 3</div>
  <div class="bg-blue-500 text-white w-16 h-8">元素 4</div>
  <div class="bg-green-500 text-white w-24 h-12">元素 5</div>
  <div class="bg-red-500 text-white w-20 h-10">元素 6</div>
</div>
```

单独控制子元素

```html
<div class="grid grid-cols-4 gap-4 bg-gray-100 p-4 h-32 text-white text-center justify-items-center items-center">
  <div class="bg-blue-500 col-span-2 w-full h-16">跨 n 列</div>
  <div class="bg-green-500 w-16 h-16">元素 2</div>
  <div class="bg-red-500 w-16 h-16">元素 3</div>
</div>
```

```html
<div
  class="grid grid-cols-3 grid-rows-3 gap-4 bg-gray-100 p-4 h-48 text-white text-center justify-items-center items-center">
  <div class="bg-blue-500 row-span-2 w-16 h-full">跨 n 行</div>
  <div class="bg-green-500 w-16 h-16">元素 2</div>
  <div class="bg-red-500 w-16 h-16">元素 3</div>
  <div class="bg-yellow-500 w-16 h-16">元素 4</div>
</div>
```

```html
<div class="grid grid-cols-4 gap-4 bg-gray-100 p-4 h-64 text-white text-center justify-items-center items-center">
  <div class="bg-blue-500 col-start-2 col-end-4 w-full h-16">指定列起止</div>
  <div class="bg-green-500 w-16 h-16">元素 2</div>
  <div class="bg-red-500 w-16 h-16">元素 3</div>
</div>
```

```html
<div
  class="grid grid-cols-3 grid-rows-4 gap-4 bg-gray-100 p-4 h-48 text-white text-center justify-items-center items-center">
  <div class="bg-blue-500 row-start-2 row-end-4 w-16 h-full">指定行起止</div>
  <div class="bg-green-500 w-16 h-16">元素 2</div>
  <div class="bg-red-500 w-16 h-16">元素 3</div>
  <div class="bg-yellow-500 w-16 h-16">元素 4</div>
</div>
```

### 控制列数

- 父元素 grid-cols- → grid 一共多少列

- 子元素 col-span- → 设置自己占几列

以后台布局为例

```html
<div class="h-screen grid grid-rows-[50px_1fr_50px]">
  <header class="bg-blue-500 text-white p-4">Header</header>
  <main class="grid grid-cols-[200px_1fr] min-h-0">
    <aside class="bg-gray-200 p-4">Sidebar</aside>
    <section class="bg-white p-4">Content</section>
  </main>
  <footer class="bg-blue-500 text-white p-4">Footer</footer>
</div>
```

```html
<div class="h-screen grid grid-cols-[200px_1fr]">
  <aside class="bg-gray-200 p-4">Sidebar</aside>
  <div class="grid grid-rows-[50px_1fr_50px] min-h-0">
    <header class="bg-blue-500 text-white p-2">Header</header>
    <main class="bg-white p-4 overflow-auto">Content</main>
    <footer class="bg-blue-500 text-white p-2">Footer</footer>
  </div>
</div>
```

仪表盘效果

```html
<div class="grid grid-cols-3 gap-4 p-4">
  <div class="col-span-3 bg-gray-300 h-24"></div>

  <!-- 通过父容器的 grid-cols- 和子容器的 col-span 共同决定 -->
  <div class="col-span-1 bg-blue-400 h-40"></div>
  <div class="col-span-2 bg-green-500 h-40"></div>

  <div class="col-span-3 bg-gray-300 h-28"></div>
  <div class="col-span-3 bg-gray-300 h-28"></div>
</div>
```
