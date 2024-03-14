# 按 module 拆分路由

## 步骤

### 创建项目

```sh
ng new demo --routing
```

### 创建外部组件

```sh
ng g c main/aaa
ng g c main/bbb
```

`app.component.html`

```html
<div id="aaa">这里是外层顶部</div>
<router-outlet></router-outlet>
<div id="bbb">这里是外层底部</div>
```

`app.component.css`

```css
#aaa {
  background-color: brown;
}

#bbb {
  background-color: burlywood;
}
```

### 创建总路由

`app-routing.module.ts`

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";
import { AaaComponent } from "./main/aaa/aaa.component";
import { BbbComponent } from "./main/bbb/bbb.component";

const routes: Routes = [
  { path: "aaa", component: AaaComponent },
  { path: "bbb", component: BbbComponent },
  {
    path: "sub",
    loadChildren: () => import("./sub/sub.module").then((m) => m.SubModule),
  },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}
```

### 创建 sub module

```sh
ng g m sub --routing
```

### 创建 sub module 下组件

```sh
ng g c sub/ccc --module=sub
ng g c sub/ddd --module=sub
```

### 创建 sub module 路由

`sub/sub-routing.module.ts`

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";
import { CccComponent } from "./ccc/ccc.component";
import { DddComponent } from "./ddd/ddd.component";

const routes: Routes = [
  { path: "ccc", component: CccComponent },
  { path: "ddd", component: DddComponent },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class SubRoutingModule {}
```

### 注册 sub module 下的组件

`sub/sub.module.ts`

```typescript
import { NgModule } from "@angular/core";
import { CccComponent } from "./ccc/ccc.component";
import { DddComponent } from "./ddd/ddd.component";
import { SubRoutingModule } from "./sub-routing.module";

@NgModule({
  declarations: [CccComponent, DddComponent],
  imports: [SubRoutingModule],
})
export class SubModule {}
```

### 更新总 module

`app.module.ts`

```typescript
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { AaaComponent } from './main/aaa/aaa.component';
import { BbbComponent } from './main/bbb/bbb.component';
import { SubModule } from './sub/sub.module';

@NgModule({
  declarations: [AppComponent, AaaComponent, BbbComponent],
  imports: [BrowserModule, AppRoutingModule, SubModule],
  providers: [],
  bootstrap: [AppComponent],
})
export class AppModule {}
```

## 测试

```sh
http://localhost:4200/aaa
http://localhost:4200/sub/ddd
```
