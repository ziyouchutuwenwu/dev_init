# flex 布局说明

## 说明

[参考连接](https://www.ruanyifeng.com/blog/2015/07/flex-grammar.html)

### flex 容器属性

#### display

```css
.box {
  display: flex;
}
```

#### 主轴方向

```css
.box {
  flex-direction: row | row-reverse | column | column-reverse;
}
```

#### 换行

```css
.box {
  flex-wrap: nowrap | wrap | wrap-reverse;
}
```

#### 主轴对齐

设置子项目在主轴上对齐方式

```css
.box {
  justify-content: flex-start | flex-end | center | space-between | space-around;
}
```

#### 交叉轴对齐

align-items 是针对单行的，是把单行来当做一个整体进行对齐方式操作

```css
.box {
  align-items: flex-start | flex-end | center | baseline | stretch;
}
```

align-content 是针对多行的，是把多行来当做一个整体进行对齐方式操作

```css
.box {
  align-content: flex-start | flex-end | center | space-between | space-around | stretch;
}
```

### 子元素属性

#### order

属性定义项目的排列顺序。数值越小，排列越靠前，默认为 0

```css
.item {
  order: <integer>;
}
```

#### flex-grow

属性定义项目的放大比例，默认为 0，即如果存在剩余空间，也不放大

```css
.item {
  flex-grow: <number>; /* default 0 */
}
```

#### flex-shrink

定义了项目的缩小比例，默认为 1，即如果空间不足，该项目将缩小

```css
.item {
  flex-shrink: <number>; /* default 1 */
}
```

#### flex-basis

定义了在分配多余空间之前，项目占据的主轴空间（main size）。浏览器根据这个属性，计算主轴是否有多余空间。它的默认值为 auto，即项目的本来大小

```css
.item {
  flex-basis: <length> | auto; /* default auto */
}
```

#### flex

flex 属性是 flex-grow, flex-shrink 和 flex-basis 的简写，默认值为 0 1 auto。后两个属性可选。

```css
.item {
  flex: none | [ < "flex-grow" > < "flex-shrink" >? || < "flex-basis" >];
}
```

#### align-self

允许单个项目有与其他项目不一样的对齐方式，可覆盖 align-items 属性。默认值为 auto，表示继承父元素的 align-items 属性，如果没有父元素，则等同于 stretch

```css
.item {
  align-self: auto | flex-start | flex-end | center | baseline | stretch;
}
```

### 辅助配置

比较有用的辅助配置

```css
div {
  display: flex;
  border: #8f8f94 solid 1px;
  margin: 20px;
}
```
