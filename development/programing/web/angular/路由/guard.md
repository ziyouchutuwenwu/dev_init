# guard

## 说明

用于控制路由的权限

## 例子

### 准备工作

```sh
ng g c login
ng g c demo1
ng g c demo2
```

### 配置路由

app.routes.ts

```typescript
import { Routes } from "@angular/router";
import { contentPageAuthGuard, loginPageAuthGuard } from "./auth/auth-guard";
import { Demo2 } from "./demo2/demo2";
import { Demo1 } from "./demo1/demo1";
import { Login } from "./login/login";

export const routes: Routes = [
  //  默认路由
  { path: "", pathMatch: "full", redirectTo: "/main" },
  {
    path: "login",
    component: Login,
    // data: { loginParam: ['aaaaaaa'] },
    canActivate: [loginPageAuthGuard],
  },
  {
    path: "main",
    canActivate: [contentPageAuthGuard],
    children: [
      {
        path: "demo1",
        // data: { loginParam: ['demo1 aaa'] },
        component: Demo1,
      },
      {
        path: "demo2",
        // data: { loginParam: ['demo2 aaa'] },
        component: Demo2,
      },
    ],
  },
];
```

app.html

```html
<router-outlet></router-outlet>
```

### service

```sh
ng g s auth/auth
```

auth.ts

```typescript
import { Injectable } from "@angular/core";
import { Router } from "@angular/router";

@Injectable({
  providedIn: "root",
})
export class Auth {
  private _isLogin = false;

  constructor(private router: Router) {}

  login(): void {
    this._isLogin = true;
  }

  isLogin(): boolean {
    return this._isLogin;
  }

  logout(): void {
    this._isLogin = false;
  }

  toPage(url: string) {
    this.router.navigate([url]);
  }
}
```

### 创建 guard

```sh
ng g guard auth/auth
```

auth-guard.ts

```typescript
import { inject } from "@angular/core";
import { CanActivateFn } from "@angular/router";
import { Auth } from "./auth";

// 内容页用
export const contentPageAuthGuard: CanActivateFn = (route, state) => {
  const auth: Auth = inject(Auth);
  if (auth.isLogin()) {
    console.log("当前在内容页, 已经登录");
    return true;
  }

  // let param = route.data['contentParam'][0];
  console.log("当前 %s, 未登录, 准备跳转到 login", state.url);
  auth.toPage("/login");

  return false;
};

// 登录页面用
export const loginPageAuthGuard: CanActivateFn = (route, state) => {
  const auth: Auth = inject(Auth);
  if (auth.isLogin()) {
    console.log("当前在登录页, 已经登录, 准备跳转到 main");
    auth.toPage("/main");
    return true;
  }

  // let param = route.data['loginParam'][0];
  console.log("当前 %s, 未登录", state.url);
  return true;
};
```

### 测试

```sh
http://localhost:4200/
```
