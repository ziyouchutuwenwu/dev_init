# module

## 说明

main.ts 里面就是启动流程

## 创建

手动创建 module

```sh
ng generate module aaa

# 同时创建路由
ng generate module ccc --module=app --routing=true
```

## 独立模式项目

手动创建完 module 以后，另外需要修改 main.ts

```typescript
bootstrapApplication(AppComponent, {
  // 这里是手动引入的模块
  providers: [importProvidersFrom(XxxModule)],
}).catch((err) => console.error(err));
```
