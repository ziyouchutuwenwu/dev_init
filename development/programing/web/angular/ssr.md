# ssr

## 说明

页面渲染的时候，js 转为 html，有利于 seo

## 步骤

### ssr 支持

新项目

```sh
ng new demo --ssr
```

给已有项目添加 ssr 支持

```sh
ng add @angular/ssr
```

### 关键代码

见 server.ts

### 打包

```sh
ng build
```

### 运行

server 和 browser 都需要

```sh
# 对于在哪里运行，没有要求，都可以
PORT=1234 node server/server.mjs
```
