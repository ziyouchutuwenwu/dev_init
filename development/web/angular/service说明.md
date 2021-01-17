# service 注入方式

## 全局注入

service 里面如果有声明如下部分，则无论是否在 module 的 provider 里面注册，都是全局的 service

```typescript
@Injectable({
  providedIn: 'root',
})
```

或者，在 app.module.ts 里面

```typescript
providers: [DemoService],
```

## 组件级别注入

service 本身，注释`@Injectable`，然后在组件的声明区域

```typescript
@Component({
  selector: 'app-my',
  providers: [DemoService]
})
```

## module 级注入

module 级别需要一个单独包装 service 的 module，否则会陷入依赖循环，[参考连接](https://segmentfault.com/a/1190000019500553#item-5)

一般用于懒加载，懒加载用于提高性能

### 步骤

在路由里面添加如下

```typescript
{ path: 'demo', loadChildren: () => import('../pages/demo/demo.module')
```

创建单独的 module。

```sh
ng g m LazyServiceModule
```

在 DemoService 的声明里面，改下面部分

```typescript
@Injectable({
  providedIn: LazyServiceModule
})
```

修改真正需要独立的 module，在 imports 里面，加入 LazyServiceModule 即可，参考下面

```typescript
@NgModule({
  declarations: [MyComponent],
  imports: [
    CommonModule,
    LazyServiceModule
  ],
  exports: [
    MyComponent
  ],
  providers: []
})
```

component 内写

假如有组件 MyComponent，需要使用某 service

```typescript
export class MyComponent implements OnInit {
  constructor(private demoService: DemoService) {}

  ngOnInit(): void {
    this.demoService.demo();
  }
}
```
