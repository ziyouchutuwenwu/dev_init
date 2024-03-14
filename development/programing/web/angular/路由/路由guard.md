# 路由 guard

## 说明

可用于无权限访问时候做页面跳转

[参考连接](https://www.cnblogs.com/banluduxing/p/9380697.html)

[官方文档](https://angular.cn/api/router/CanActivateFn)

| 类型             | 说明                                                      |
| ---------------- | --------------------------------------------------------- |
| CanActivate      | 这种类型的 Guard 用来控制是否允许进入当前的路径           |
| CanActivateChild | 这种类型的 Guard 用来控制是否允许进入当前路径的所有子路径 |
| CanDeactivate    | 用来控制是否能离开当前页面进入别的路径                    |
| CanLoad          | 用于控制一个异步加载的子模块是否允许被加载。              |

## 例子

### 创建项目

```sh
ng new demo --routing
cd demo
ng g c home
ng g c login
```

### 配置路由

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";
import { HomeComponent } from "./home/home.component";
import { LoginComponent } from "./login/login.component";
import { AuthGuard } from "./auth/auth.guard";

export const appRoutes: Routes = [
  { path: "", redirectTo: "/main", pathMatch: "full" },
  { path: "login", component: LoginComponent },
  {
    path: "main",
    component: HomeComponent,
    canActivate: [AuthGuard.isAuthed],
    // 传入参数给AuthGuard，可选
    data: { myParam: ["sss"] },
  },
];

@NgModule({
  imports: [RouterModule.forRoot(appRoutes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}
```

app.component.html

```html
<router-outlet></router-outlet>
```

### 创建 service

```sh
ng g service auth/auth
```

```typescript
import { Injectable } from "@angular/core";
import { Router } from "@angular/router";

@Injectable({
  providedIn: "root",
})
export class AuthService {
  private isLoggedIn = false;

  constructor(private router: Router) {}

  login(): void {
    this.isLoggedIn = true;
  }

  isLogin(): boolean {
    return this.isLoggedIn;
  }

  logout(): void {
    this.isLoggedIn = false;
  }

  toLoginPage() {
    if (!this.isLoggedIn) {
      this.router.navigate(["login"]);
    }
  }
}
```

### 创建 guard

```sh
ng g guard auth/auth
```

```typescript
import { Injectable, inject } from "@angular/core";
import {
  ActivatedRouteSnapshot,
  CanActivateFn,
  RouterStateSnapshot,
} from "@angular/router";
import { AuthService } from "./auth.service";

@Injectable({
  providedIn: "root",
})
export class AuthGuard {
  static isAuthed: CanActivateFn = (
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ) => {
    const authService: AuthService = inject(AuthService);
    if (authService.isLogin()) {
      return true;
    }

    let aaa = route.data["myParam"][0];
    console.log("登录参数" + aaa);
    console.log(state.url);
    authService.toLoginPage();
    return false;
  };
}
```

### 测试

```sh
http://localhost:4200/main
```
