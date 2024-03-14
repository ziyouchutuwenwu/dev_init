# flex 布局说明

## 说明

参考连接: [阮一峰](https://www.ruanyifeng.com/blog/2015/07/flex-grammar.html)

### flex 容器属性

#### display

```css
.box {
  display: flex;
}
```

#### 主轴方向

就是子元素在容器里面横着还是竖着排

| row                  | row-reverse          | column               | column-reverse       |
| -------------------- | -------------------- | -------------------- | -------------------- |
| 水平方向，起点在左端 | 水平方向，起点在右端 | 垂直方向，起点在上沿 | 垂直方向，起点在下沿 |

```css
.box {
  flex-direction: row | row-reverse | column | column-reverse;
}
```

#### 换行

子项目在主轴方向满了以后，如何换行

| nowrap | wrap               | wrap-reverse       |
| ------ | ------------------ | ------------------ |
| 不换行 | 换行，第一行在上方 | 换行，第一行在下方 |

```css
.box {
  flex-wrap: nowrap | wrap | wrap-reverse;
}
```

#### 主轴对齐

设置子项目在主轴上对齐方式

| flex-start | flex-end | center | space-between                  | space-around                                                         |
| ---------- | -------- | ------ | ------------------------------ | -------------------------------------------------------------------- |
| 左对齐     | 右对齐   | 居中   | 两端对齐，项目之间的间隔都相等 | 每个项目两侧的间隔相等。所以，项目之间的间隔比项目与边框的间隔大一倍 |

```css
.box {
  justify-content: flex-start | flex-end | center | space-between | space-around;
}
```

#### 交叉轴对齐

设置子项目在交叉轴上对齐方式

| flex-start       | flex-end         | center           | baseline                   | stretch                                             |
| ---------------- | ---------------- | ---------------- | -------------------------- | --------------------------------------------------- |
| 交叉轴的起点对齐 | 交叉轴的终点对齐 | 交叉轴的中点对齐 | 项目的第一行文字的基线对齐 | 如果项目未设置高度或设为 auto，将占满整个容器的高度 |

```css
.box {
  align-items: flex-start | flex-end | center | baseline | stretch;
}
```

#### 多根轴线

用于定义多根轴线的对齐方式

如果项目只有一根轴线，该属性不起作用

| flex-start         | flex-end           | center             | space-between                            | space-around                                                           | stretch            |
| ------------------ | ------------------ | ------------------ | ---------------------------------------- | ---------------------------------------------------------------------- | ------------------ |
| 与交叉轴的起点对齐 | 与交叉轴的终点对齐 | 与交叉轴的中点对齐 | 与交叉轴两端对齐，轴线之间的间隔平均分布 | 每根轴线两侧的间隔都相等。所以，轴线之间的间隔比轴线与边框的间隔大一倍 | 轴线占满整个交叉轴 |

```css
.box {
  align-content: flex-start | flex-end | center | space-between | space-around |
    stretch;
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
