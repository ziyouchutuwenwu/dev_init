# ssr

如果需要 seo，则可以考虑 ssr 方便爬虫爬取

## 步骤

### 添加依赖

```sh
ng add @nguniversal/express-engine
```

### 测试

```sh
npm run dev:ssr
```

### 允许其它 ip 访问

server.ts

```typescript
const server = express();
```

下插入

```typescript
server.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  next();
});
```

### 编译

```sh
npm run build:ssr
```

### 运行

- 正式服务器建议装 pm2, 默认端口 4000

- 必须在 dist 目录外运行

```sh
pm2 start dist/app1/server/main.js
```
