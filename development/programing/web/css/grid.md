# grid

## 说明

没有主轴和交叉轴的概念，只有 col 和 row

## 行列

| 项目       | grid-cols-xxx | grid-rows-xxx      |
| ---------- | ------------- | ------------------ |
| 默认优先级 | 更高          | 较低（依赖列定义） |
| 定义       | 必须显式定义  | 可选               |

## 对齐

### 针对整个 grid

| 类          | 说明              |
| ----------- | ----------------- |
| justify-xxx | 水平针对整个 grid |
| align-xxx   | 垂直针对整个 grid |
| place-xxx   | 同时设置两者      |

### 针对 grid 所有子项

| 类                | 说明         |
| ----------------- | ------------ |
| justify-items-xxx | 水平所有子项 |
| align-items-xxx   | 垂直所有子项 |
| place-items-xxx   | 同时设置两者 |

### 单独子项设置

可以覆盖父级设置

| 类               | 说明             |
| ---------------- | ---------------- |
| justify-self-xxx | 水平设置子项自己 |
| align-self-xxx   | 垂直设置子项自己 |
| place-self-xxx   | 同时设置两者     |

### 对齐说明

| 类      | 效果     |
| ------- | -------- |
| start   | 左/上    |
| end     | 右/下    |
| center  | 居中     |
| stretch | 拉伸填充 |
| between | 两端分散 |
| around  | 环绕分散 |
| evenly  | 完全均匀 |
