# module

## 注意

standalone 项目, module 跟随项目启动

main.ts

```typescript
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { importProvidersFrom } from '@angular/core';

bootstrapApplication(AppComponent, {
  providers: [
    importProvidersFrom(XxxModule)
  ],
}).catch((err) => console.error(err));
```
