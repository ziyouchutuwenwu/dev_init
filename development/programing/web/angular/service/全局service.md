# 全局 service

用于全局共享数据

## 例子

### 创建项目

```sh
ng g c demo1
ng g c demo2
ng g s demo
```

### service 注册

默认创建的 service 自带声明

```typescript
@Injectable({
  providedIn: 'root'
})
```

或者在 app.module.ts 里面

```typescript
providers: [DemoService],
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

### service 读写

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

app-routing.module.ts

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";
import { Demo2Component } from "./demo2/demo2.component";
import { Demo1Component } from "./demo1/demo1.component";

const routes: Routes = [
  { path: "demo1", component: Demo1Component },
  { path: "demo2", component: Demo2Component },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}
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
