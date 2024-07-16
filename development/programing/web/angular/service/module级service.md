# module 级 service

## 说明

service 注册，必须使用一个单独的 proxy 的 module,这个 proxy 的 module 再注册到子模块的 module 里面，避免循环注册，[参考连接](https://segmentfault.com/a/1190000019500553#item-5)

项目里面为

```sh
DemoService 通过 providedIn 注册到 ServiceWrapperModule
subModule 内 import ServiceWrapperModule
```

## 步骤

### 创建项目

```sh
ng new demo
cd demo
ng g m sub --routing
ng g c sub/aaa --standalone=false --module=sub
ng g c sub/bbb --standalone=false --module=sub
ng g m sub/service
ng g s sub/service/demo
```

### 页面

app.component.html

```html
<div>
  <a [routerLink]="['sub', {outlets:{'aux1' :'aaa'}}]">aaa</a>
</div>
<div>
  <a [routerLink]="['sub', {outlets:{'aux1' :null}}]">结束 aaa</a>
</div>
<div>
  <a [routerLink]="['sub', {outlets:{'aux2' :'bbb'}}]">bbb</a>
</div>
<div>
  <a [routerLink]="['sub', {outlets:{'aux2' :null}}]">结束 bbb</a>
</div>
<div>
  <router-outlet name="aux1"></router-outlet>
</div>
<div>
  <router-outlet name="aux2"></router-outlet>
</div>
```

bbb.component.html

```html
<p>demo2 works!</p>
{{showValue}}
```

### component

```typescript
import { Component, OnInit } from "@angular/core";
import { DemoService } from "../service/demo.service";

@Component({
  selector: "app-bbb",
  templateUrl: "./bbb.component.html",
  styleUrls: ["./bbb.component.css"],
})
export class BbbComponent implements OnInit {
  public showValue = 0;
  constructor(private demoService: DemoService) {
    console.log("app-demo2");
  }

  ngOnInit(): void {
    this.showValue = this.demoService.get();
  }
}
```

aaa.component.ts

```typescript
import { Component, OnInit } from "@angular/core";
import { DemoService } from "../service/demo.service";

@Component({
  selector: "app-aaa",
  templateUrl: "./aaa.component.html",
  styleUrls: ["./aaa.component.css"],
})
export class AaaComponent {
  constructor(private demoService: DemoService) {}

  ngOnInit(): void {
    this.demoService.set(11111);
  }
}
```

### 入口配置

```typescript
import { Component } from "@angular/core";
import { RouterModule, RouterOutlet } from "@angular/router";

@Component({
  selector: "app-root",
  standalone: true,
  // 引入 RouterModule
  imports: [RouterOutlet, RouterModule],
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.css",
})
export class AppComponent {
  title = "demo";
}
```

### 路由

app.routes.ts

```typescript
import { Routes } from "@angular/router";

export const routes: Routes = [
  {
    path: "sub",
    loadChildren: () => import("./sub/sub.module").then((module) => module.SubModule),
  },
];
```

sub-routing.module.ts

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";
import { AaaComponent } from "./aaa/aaa.component";
import { BbbComponent } from "./bbb/bbb.component";

const routes: Routes = [
  { path: "aaa", component: AaaComponent, outlet: "aux1" },
  { path: "bbb", component: BbbComponent, outlet: "aux2" },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class subRoutingModule {}
```

### service

demo.service.ts

```typescript
import { Injectable } from "@angular/core";
import { ServiceModule } from "./service.module";

@Injectable({
  // service 注册到包装 module
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

### module

sub.module.ts

```typescript
import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { SubRoutingModule } from "./sub-routing.module";
import { AaaComponent } from "./aaa/aaa.component";
import { BbbComponent } from "./bbb/bbb.component";
import { ServiceModule } from "./service/service.module";

@NgModule({
  declarations: [AaaComponent, BbbComponent],
  imports: [
    CommonModule,
    // service 的包装 module
    ServiceModule,
    SubRoutingModule,
  ],
})
export class SubModule {}
```

## 测试

```sh
http://localhost:4200/
```
