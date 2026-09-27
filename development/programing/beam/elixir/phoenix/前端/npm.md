# npm

## 说明

不是所有的 npm 包都支持

## 例子

要在 assets 目录下

```sh
cd assets
npm install dayjs
```

app.js

```javascript
import dayjs from "dayjs";

console.log("Today is:", dayjs().format("YYYY-MM-DD"));
```
