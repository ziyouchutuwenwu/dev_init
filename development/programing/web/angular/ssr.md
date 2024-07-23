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

具体见 package.json

必须在 dist 目录外运行, 默认端口 4000

```sh
PORT=1234 node dist/demo/server/server.mjs
```
