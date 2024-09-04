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
ng new demo
cd demo
ng g c home
ng g c login
```

### 配置路由

app.routes.ts

```typescript
import { Routes } from '@angular/router';
import { contentPageAuthGuard, loginPageAuthGuard } from './auth/auth.guard';
import { LoginComponent } from './login/login.component';
import { MainComponent } from './main/main.component';
import { Demo1Component } from './content/demo1/demo1.component';
import { Demo2Component } from './content/demo2/demo2.component';

export const routes: Routes = [
  //  默认路由
  { path: '', pathMatch: 'full', redirectTo: '/main' },
  {
    path: 'login',
    component: LoginComponent,
    // data: { loginParam: ['aaaaaaa'] },
    canActivate: [loginPageAuthGuard],
  },
  {
    path: 'main',
    component: MainComponent,
    canActivate: [contentPageAuthGuard],
    children: [
      {
        path: 'demo1',
        // data: { loginParam: ['demo1 aaa'] },
        component: Demo1Component,
      },
      {
        path: 'demo2',
        // data: { loginParam: ['demo2 aaa'] },
        component: Demo2Component,
      },
    ],
  },
];
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
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private _isLogin = true;

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

```typescript
import { inject } from '@angular/core';
import { CanActivateFn } from '@angular/router';
import { AuthService } from './auth.service';

// 内容页用
export const contentPageAuthGuard: CanActivateFn = (route, state) => {
  const authService: AuthService = inject(AuthService);
  if (authService.isLogin()) {
    console.log('当前在内容页, 已经登录');
    return true;
  }

  // let param = route.data['contentParam'][0];
  console.log('当前 %s, 未登录, 准备跳转到 login', state.url);
  authService.toPage('/login');

  return false;
};

// 登录页面用
export const loginPageAuthGuard: CanActivateFn = (route, state) => {
  const authService: AuthService = inject(AuthService);
  if (authService.isLogin()) {
    console.log('当前在登录页, 已经登录, 准备跳转到 main');
    authService.toPage('/main');
    return true;
  }

  // let param = route.data['loginParam'][0];
  console.log('当前 %s, 未登录', state.url);
  return true;
};
```

### 测试

```sh
http://localhost:4200/
```
