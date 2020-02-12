# service注入方式

## 全局注入

- service里面如果有声明如下部分，则无论是否在module的provider里面注册，都是全局的service

```typescript
@Injectable({
  providedIn: 'root',
})
```

- 或者，在app.module.ts里面

```typescript
providers: [DemoService],
```

## 组件级别注入

- service本身，注释`@Injectable`，然后在组件的声明区域

```typescript
@Component({
  selector: 'app-my',
  providers: [DemoService]
})
```

## module级别，需要一个单独包装service的module，否则会陷入依赖循环，[参考连接](https://segmentfault.com/a/1190000019500553#item-5)

- 一般用于懒加载，懒加载用于提高性能，在路由里面添加`{ path: 'demo', loadChildren: () => import('../pages/demo/demo.module')`即可。
- 创建单独的module。`ng g m LazyServiceModule`, 在`DemoService`的声明里面，改下面部分

```typescript
@Injectable({
  providedIn: LazyServiceModule
})
```

- 修改真正需要独立的module，在imports里面，加入`LazyServiceModule`即可，参考下面

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

- component内写

- 假如有组件MyComponent，需要使用某service

```typescript
export class MyComponent implements OnInit {

  private demoService: DemoService;
  constructor(injectedDemoService: DemoService) {
    this.demoService = injectedDemoService;
  }

  ngOnInit(): void {
    this.demoService.demo();
  }
}
