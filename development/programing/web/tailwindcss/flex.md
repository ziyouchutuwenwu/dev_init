# flex

## 说明

- 父元素 justify-xxx → 水平方向（主轴）排列

- 父元素 items-xxx → 垂直方向（交叉轴）排列

- 父元素 gap/space-x/space-y → 控制子元素之间间距

## 例子

子元素保持边距

```html
<div class="flex space-x-4 bg-gray-100">
  <div class="bg-blue-500 text-white">A</div>
  <div class="bg-green-500 text-white">B</div>
  <div class="bg-red-500 text-white">C</div>
</div>
```

水平居中

```html
<div class="flex justify-center space-x-4 bg-gray-100 h-64">
  <div class="bg-blue-500 text-white">A</div>
  <div class="bg-green-500 text-white">B</div>
  <div class="bg-red-500 text-white">C</div>
</div>
```

垂直居中

```html
<div class="flex items-center space-y-4 bg-gray-100 h-64">
  <div class="bg-blue-500 text-white">A</div>
  <div class="bg-green-500 text-white">B</div>
  <div class="bg-red-500 text-white">C</div>
</div>
```

交叉轴上单独控制子元素

```html
<div class="flex items-center bg-gray-100 h-64">
  <div class="bg-blue-500 text-white">A</div>
  <div class="bg-green-500 text-white self-start">B</div>
  <div class="bg-red-500 text-white">C</div>
</div>
```

主轴上单独控制子元素

```html
<div class="flex items-center bg-gray-100 h-64 w-full px-4">
  <div class="bg-blue-500 text-white mr-20">A</div>
  <div class="bg-green-500 text-white">B</div>
  <div class="bg-red-500 text-white">C</div>
</div>
```
