# js

## 例子

### 目录

assets 目录结构

```sh
assets
├── app.js
└── demo
    ├── aa.ts
    └── bb.ts
```

### 代码

app.js

```typescript
import { DemoClass } from "./demo/aa";
import * as bb from "./demo/bb";

const demo = new DemoClass();
demo.demo1();

bb.demo2();
```

aa.ts

```typescript
export class DemoClass {
  demo1(): void {
    console.log("demo1 in DemoClass");
  }
}
```

bb.ts

```typescript
export function demo2(): void {
  console.log("demo2 in bb");
}
```
