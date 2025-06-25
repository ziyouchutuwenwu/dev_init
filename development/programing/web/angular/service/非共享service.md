# 非共享 service

多组件注册同一个 service, service 会被多次实例化, 因此不能共享数据, 只能用于处理逻辑

## 例子

### 创建项目

```sh
ng new demo
cd demo
ng g c demo1
ng g c demo2
ng g s demo
```

### service 代码

demo.service.ts

```typescript
import { Injectable } from "@angular/core";

@Injectable({
  providedIn: "root",
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

### 组件代码

demo1.component.ts

```typescript
import { Component, OnInit } from "@angular/core";
import { DemoService } from "../demo.service";

@Component({
  selector: "app-demo1",
  templateUrl: "./demo1.component.html",
  styleUrls: ["./demo1.component.css"],
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
import { DemoService } from "../demo.service";

@Component({
  selector: "app-demo2",
  templateUrl: "./demo2.component.html",
  styleUrls: ["./demo2.component.css"],
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

app.routes.ts

```typescript
import { Routes } from "@angular/router";
import { Demo1Component } from "./demo1/demo1.component";
import { Demo2Component } from "./demo2/demo2.component";

export const routes: Routes = [
  { path: "demo1", component: Demo1Component },
  { path: "demo2", component: Demo2Component },
];
```

app.component

```typescript
import { Component } from "@angular/core";
import { RouterModule, RouterOutlet } from "@angular/router";

@Component({
  selector: "app-root",
  standalone: true,
  // 导入 RouterModule
  imports: [RouterOutlet, RouterModule],
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.css",
})
export class AppComponent {
  title = "demo";
}
```

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

### 测试

```sh
http://localhost:4200/
```
