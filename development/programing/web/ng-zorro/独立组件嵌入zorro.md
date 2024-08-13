# 独立组件嵌入 zorro

## 说明

独立模式组件嵌入 ng-zorro

## 步骤

- 创建 module

- module 的 declarations 和 exports 都添加 zorro 的组件，imports 添加依赖库

- 独立组件 import 上面那个 module

## 例子

创建项目

```sh
ng new demo
cd demo
```

增加 zorro 支持

```sh
ng add ng-zorro-antd
```

创建 module

```sh
ng generate module zorro
```

创建测试组件

```sh
ng g ng-zorro-antd:card-basic card
```

在 zorro.module.ts 内注册 card 组件

```typescript
@NgModule({
  // 声明
  declarations: [CardComponent],
  // 导出，不可以缺
  exports: [CardComponent],
  imports: [CommonModule, NzCardModule],
})
```

app.component.ts

```typescript
imports: [RouterOutlet, ZorroModule],
```

app.component.html

```html
<app-card></app-card>
```

## 测试

```sh
ng s
```
