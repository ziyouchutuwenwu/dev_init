# 共享 service

单例，共享数据

## 说明

例子为 自定义 module 内，创建 component 和 service 的例子

### 创建项目

```sh
ng new demo
cd demo
ng g m sub --routing
ng g c sub/demo1 --standalone=false --module=sub
ng g c sub/demo2 --standalone=false --module=sub
ng g m sub/service
ng g s sub/service/demo
```

### service

demo.service.ts

```typescript
import { Injectable } from "@angular/core";
import { ServiceModule } from "./service.module";

@Injectable({
  // 注册到中间的 module
  providedIn: ServiceModule,
})
export class DemoService {
  private _value = -1;

  constructor() {
    console.log("on service constructor");
  }

  get() {
    console.log("on service get", this._value);
    return this._value;
  }

  set(value: number) {
    console.log("on service set");
    this._value = value;
  }
}
```

sub.module.ts

```typescript
import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";

import { SubRoutingModule } from "./sub-routing.module";
import { Demo1Component } from "./demo1/demo1.component";
import { Demo2Component } from "./demo2/demo2.component";
import { ServiceModule } from "./service/service.module";

@NgModule({
  declarations: [Demo1Component, Demo2Component],
  imports: [
    CommonModule,
    // 注册
    ServiceModule,
    SubRoutingModule,
  ],
})
export class SubModule {}
```

### component

demo1.component.ts

```typescript
import { Component, OnInit } from "@angular/core";
import { DemoService } from "../service/demo.service";

@Component({
  selector: "app-demo1",
  templateUrl: "./demo1.component.html",
  styleUrl: "./demo1.component.css",
})
export class Demo1Component implements OnInit {
  constructor(private demoService: DemoService) {
    console.log("app-demo1");
  }

  ngOnInit(): void {
    this.demoService.set(11111);
  }
}
```

demo2.component.ts

```typescript
import { Component, OnInit } from "@angular/core";
import { DemoService } from "../service/demo.service";

@Component({
  selector: "app-demo2",
  templateUrl: "./demo2.component.html",
  styleUrl: "./demo2.component.css",
})
export class Demo2Component implements OnInit {
  public showValue = 0;
  constructor(private demoService: DemoService) {
    console.log("app-demo2");
  }

  ngOnInit(): void {
    this.showValue = this.demoService.get();
  }
}
```

### 路由

sub-routing.module.ts

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";
import { Demo1Component } from "./demo1/demo1.component";
import { Demo2Component } from "./demo2/demo2.component";

const routes: Routes = [
  { path: "demo1", component: Demo1Component },
  { path: "demo2", component: Demo2Component },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class SubRoutingModule {}
```

app.routes.ts

```typescript
import { Routes } from "@angular/router";

export const routes: Routes = [
  {
    path: "",
    loadChildren: () => import("./sub/sub.module").then((m) => m.SubModule),
  },
];
```

### 页面

demo2.component.html

```html
<p>demo2 works!</p>
{{showValue}}
```

app.component.html

```html
<div>
  <a [routerLink]="['/demo1']">demo1</a>
</div>
<div>
  <a [routerLink]="['/demo2']">demo2</a>
</div>

<router-outlet></router-outlet>
```

### 入口注册 module

app.component.ts

```typescript
import { Component } from "@angular/core";
import { RouterModule, RouterOutlet } from "@angular/router";
import { SubModule } from "./sub/sub.module";

@Component({
  selector: "app-root",
  standalone: true,
  // 导入 RouterModule
  imports: [RouterOutlet, RouterModule, SubModule],
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.css",
})
export class AppComponent {
  title = "demo";
}
```

### 测试

f12 看 log，切换按钮，只构造一次

```sh
http://localhost:4200/
```
