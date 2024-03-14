# module 级 service

## 说明

service 注册，必须使用一个单独的 proxy 的 module,这个 proxy 的 module 再注册到子模块的 module 里面，避免循环注册，[参考连接](https://segmentfault.com/a/1190000019500553#item-5)

## 步骤

### 创建项目

```sh
ng new demo --routing
cd demo
ng g m mod1 --routing
ng g c mod1/aaa --module mod1
ng g c mod1/bbb --module mod1

ng g m mod1/service-wrapper
ng g s mod1/service-wrapper/demo
```

### 最外层

#### 页面

app.component.html

```html
<div>
  <a [routerLink]="['mod1', {outlets:{'aux1' :'aaa'}}]">aaa</a>
</div>
<div>
  <a [routerLink]="['mod1', {outlets:{'aux1' :null}}]">结束 aaa</a>
</div>
<div>
  <a [routerLink]="['mod1', {outlets:{'aux2' :'bbb'}}]">bbb</a>
</div>
<div>
  <a [routerLink]="['mod1', {outlets:{'aux2' :null}}]">结束 bbb</a>
</div>
<div>
  <router-outlet name="aux1"></router-outlet>
</div>
<div>
  <router-outlet name="aux2"></router-outlet>
</div>
```

#### 路由

app-routing.module.ts

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";

const routes: Routes = [
  {
    path: "mod1",
    loadChildren: () =>
      import("./mod1/mod1.module").then((module) => module.Mod1Module),
  },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}
```

mod1-routing.module.ts

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";
import { AaaComponent } from "./aaa/aaa.component";
import { BbbComponent } from "./bbb/bbb.component";

export const routes: Routes = [
  { path: "aaa", component: AaaComponent, outlet: "aux1" },
  { path: "bbb", component: BbbComponent, outlet: "aux2" },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class Mod1RoutingModule {}
```

#### 服务

demo.service.ts

```typescript
import { Injectable } from "@angular/core";
import { ServiceWrapperModule } from "./service-wrapper.module";

@Injectable({
  // service 注册到包装 module
  providedIn: ServiceWrapperModule,
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

### 子模块

#### 子模块 module

mod1.module.ts

```typescript
import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";

import { Mod1RoutingModule } from "./mod1-routing.module";
import { AaaComponent } from "./aaa/aaa.component";
import { BbbComponent } from "./bbb/bbb.component";
import { ServiceWrapperModule } from "./service-wrapper/service-wrapper.module";

@NgModule({
  declarations: [AaaComponent, BbbComponent],
  imports: [
    CommonModule,
    Mod1RoutingModule,
    // service 的包装 module
    ServiceWrapperModule,
  ],
})
export class Mod1Module {}
```

#### 子模块组件

bbb.component.html

```html
<p>demo2 works!</p>
{{showValue}}
```

bbb.component.ts

```typescript
import { Component, OnInit } from "@angular/core";
import { DemoService } from "../service-wrapper/demo.service";

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
import { DemoService } from "../service-wrapper/demo.service";

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
