# ngrx

## 说明

standalone 和 非 standalone 项目主要是在启动模块的注册上有区别

## 使用场景

类似于某些业务组件的 curd

## 例子

### 创建项目

```sh
ng new demo
cd demo
npm install @ngrx/store
```

### 定义 reducer

```sh
ng g m counter
```

counter.actions.ts

```typescript
import { createAction, props } from "@ngrx/store";

export const increment = createAction("数据加1");
export const decrement = createAction("数据减1");
export const reset = createAction("数据重置");
```

counter.reducer.ts

```typescript
import { createReducer, on } from "@ngrx/store";
import { increment, decrement, reset } from "./counter.actions";

export const initialState = 0;

export const counterReducer = createReducer(
  initialState,
  on(increment, (state) => state + 1),
  on(decrement, (state) => state - 1),
  on(reset, () => initialState)
);
```

counter.module.ts

```typescript
import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { StoreModule } from "@ngrx/store";
import { counterReducer } from "./counter.reducer";

@NgModule({
  declarations: [],
  imports: [CommonModule, StoreModule.forFeature("counter", counterReducer)],
})
export class CounterModule {}
```

### 非 standalone 项目

app.component.html

```html
<button (click)="add()">add</button>
<button (click)="dec()">dec</button>
<button (click)="reinit()">reset</button>

<p>{{ counter }}</p>
```

app.component.ts

```typescript
import { Component } from "@angular/core";
import { Store } from "@ngrx/store";
import { decrement, increment, reset } from "./counter/counter.actions";

@Component({
  selector: "app-root",
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.css",
})
export class AppComponent {
  title = "my-app";

  public counter: number = 0;

  constructor(private store: Store<{ counter: number }>) {
    this.store.select("counter").subscribe((value) => {
      this.counter = value;
    });
  }

  add() {
    this.store.dispatch(increment());
  }

  dec() {
    this.store.dispatch(decrement());
  }

  reinit() {
    this.store.dispatch(reset());
  }
}
```

app.module.ts

```typescript
import { NgModule } from "@angular/core";
import { BrowserModule } from "@angular/platform-browser";
import { AppRoutingModule } from "./app-routing.module";
import { AppComponent } from "./app.component";
import { CounterModule } from "./counter/counter.module";
import { StoreModule } from "@ngrx/store";

@NgModule({
  declarations: [AppComponent],
  imports: [
    BrowserModule,
    AppRoutingModule,
    // 下面两个都要注册
    CounterModule,
    StoreModule.forRoot({}),
  ],
  providers: [],
  bootstrap: [AppComponent],
})
export class AppModule {}
```

### standalone 项目

app.component.html

```html
<button (click)="add()">add</button>
<button (click)="dec()">dec</button>
<button (click)="reinit()">reset</button>

<p>{{ counter }}</p>
```

app.component.ts

```typescript
import { Component, inject } from "@angular/core";
import { RouterOutlet } from "@angular/router";
import { Store } from "@ngrx/store";
import { decrement, increment, reset } from "./counter/counter.actions";
import { CounterModule } from "./counter/counter.module";

@Component({
  selector: "app-root",
  standalone: true,
  imports: [RouterOutlet, CounterModule],
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.css",
})
export class AppComponent {
  title = "my-app";

  public counter: number = 0;

  constructor(private store: Store<{ counter: number }> = inject(Store)) {
    this.store.select("counter").subscribe((value) => {
      this.counter = value;
    });
  }

  add() {
    this.store.dispatch(increment());
  }

  dec() {
    this.store.dispatch(decrement());
  }

  reinit() {
    this.store.dispatch(reset());
  }
}
```

main.ts

```typescript
import { bootstrapApplication } from "@angular/platform-browser";
import { AppComponent } from "./app/app.component";
import { StoreModule } from "@ngrx/store";
import { importProvidersFrom } from "@angular/core";

bootstrapApplication(AppComponent, {
  providers: [importProvidersFrom(StoreModule.forRoot({}))],
}).catch((err) => console.error(err));
```

## 测试

```sh
http://localhost:4200/
```
