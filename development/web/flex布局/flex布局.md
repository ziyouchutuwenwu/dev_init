# flex 布局说明

## 最简说明

### 直属父容器

```txt
display: flex;
设置方向flex-direction
设置横向对齐方式：justify-content: flex-end;
设置纵向对齐方式：align-items: center
```

### 子元素

```txt
设置权重 flex
可选的子元素对齐 align-self，可覆盖父容器配置的对齐方式
```

### 比较有用的辅助配置

```css
div {
  display: flex;
  border: #8f8f94 solid 1px;
  margin: 20px;
}
```

## 备注

参考连接: [uni-app](https://www.kancloud.cn/zengqs1976/uni-app/1176122) 和 [阮一峰](https://www.ruanyifeng.com/blog/2015/07/flex-grammar.html)
