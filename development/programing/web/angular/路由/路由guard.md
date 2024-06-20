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
import { LoginComponent } from './login/login.component';
import { HomeComponent } from './home/home.component';
import { contentPageAuthGuard, loginPageAuthGuard } from './auth/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: '/main', pathMatch: 'full' },
  {
    path: 'login',
    component: LoginComponent,
    canActivate: [loginPageAuthGuard],
    data: { loginParam: ['aaaaaaa'] },
  },
  {
    path: 'main',
    component: HomeComponent,
    canActivate: [contentPageAuthGuard],
    data: { contentParam: ['bbbbbbbb'] },
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

  toContentPage() {
    if (this.isLoggedIn) {
      this.router.navigate(['main']);
    }
  }

  toLoginPage() {
    if (!this.isLoggedIn) {
      this.router.navigate(['login']);
    }
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

// true 是否允许导航
export const contentPageAuthGuard: CanActivateFn = (route, state) => {
  const authService: AuthService = inject(AuthService);
  if (authService.isLogin()) {
    console.log('当前在内容页, 已经登录');
    return true;
  }

  let param = route.data['contentParam'][0];
  console.log('当前 %s, 未登录, 登录参数 %s, 准备跳转到 login', state.url, param);
  authService.toLoginPage();

  return false;
};

export const loginPageAuthGuard: CanActivateFn = (route, state) => {
  const authService: AuthService = inject(AuthService);
  if (authService.isLogin()) {
    console.log('当前在登录页, 已经登录, 准备跳转到 main');
    authService.toContentPage();
    return true;
  }

  let param = route.data['loginParam'][0];
  console.log('当前 %s, 未登录, 登录参数 %s', state.url, param);
  return true;
};
```

### 测试

```sh
http://localhost:4200/
```
