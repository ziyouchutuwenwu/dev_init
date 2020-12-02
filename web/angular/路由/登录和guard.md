# 登录和路由 guard

## 创建路由 module

```sh
ng g module appRouting
```

- 在`app.module.ts`的`imports`里面添加`AppRoutingModule`
- AppRoutingModule 里面大概改成这样

```typescript
export const appRoutes: Routes = [
  { path: "", redirectTo: "/main", pathMatch: "full" },
  { path: "login", component: LoginComponent },
  {
    path: "main",
    component: HomeComponent,
    children: [
      // { path: 'demo', component: DemoComponent },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forRoot(appRoutes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}
```

- 页面上设置 router-outlet, 用于占位
- app.component.html 里面，改成`<router-outlet></router-outlet>`

## 添加 guard

- 最常用的，可以由于无权限访问时候做页面跳转，[参考连接](https://www.cnblogs.com/banluduxing/p/9380697.html)

```sh
ng g guard auth/auth
ng g service auth/auth
```

- AuthService 大概如下

```typescript
export class AuthService {
  private isLoggedIn = false;

  constructor() {}

  login(): void {
    this.isLoggedIn = true;
  }

  isLogin(): boolean {
    return this.isLoggedIn;
  }

  logout(): void {
    this.isLoggedIn = false;
  }
}
```

- AuthGuard 大概如下

```typescript
@Injectable({
  providedIn: "root",
})
export class AuthGuard implements CanActivate {
  canActivate(
    next: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ):
    | Observable<boolean | UrlTree>
    | Promise<boolean | UrlTree>
    | boolean
    | UrlTree {
    return this.checkLogin(state.url);
  }

  constructor(private authService: AuthService, private router: Router) {}

  checkLogin(url: string) {
    if (this.authService.isLogin()) {
      return true;
    }

    this.router.navigate(["login"]);
    return false;
  }
}
```
