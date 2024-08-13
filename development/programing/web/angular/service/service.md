# service

## 说明

```sh
service 不能在 目标 module 内直接注册
需要在 service 内通过 @Injectable 注册到某个中间 module
然后在主 module 内 import 中间 module
```

## 例子

### 场景

比如，在名为 tag 的 module 内注册某个 service

### 步骤

```sh
ng g m tag
ng g m tag/service
ng g s tag/demo
```

demo.service.ts

```typescript
@Injectable({
  // providedIn: 'root',
  providedIn: ServiceModule,
})
```

tag.module.ts

```typescript
@NgModule({
  declarations: [],
  imports: [CommonModule, ServiceModule],
})
export class TagModule {}
```
