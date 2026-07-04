# rxjs

## 说明

pubsub 的模式

## 使用场景

比较适合无关联组件之间的通信

## 例子

### 创建项目

```sh
ng new demo
cd demo
npm install rxjs

ng g c c1
ng g c c2
ng g s notify
```

### 代码

notify.service.ts

```typescript
import { Injectable } from "@angular/core";
import { Observable, Subject } from "rxjs";

@Injectable({
  providedIn: "root",
})
export class NotifyService {
  private subject = new Subject<any>();

  send(data: any) {
    this.subject.next(data);
  }

  onMsg(): Observable<any> {
    return this.subject.asObservable();
  }
}
```

c1.ts

```typescript
import { Component, OnInit } from "@angular/core";
import { NotifyService } from "../notify.service";

@Component({
  selector: "app-c1",
  imports: [],
  templateUrl: "./c1.html",
  styleUrl: "./c1.css",
})
export class C1 implements OnInit {
  constructor(private notifyService: NotifyService) {}

  ngOnInit() {
    this.notifyService.onMsg().subscribe((msg) => {
      console.log("c1 got data %s", msg);
    });
  }

  send() {
    this.notifyService.send("data from c1");
  }
}
```

c1.html

```html
<button (click)="send()">发送</button>
```

c2.ts

```typescript
import { Component, OnInit } from "@angular/core";
import { NotifyService } from "../notify.service";

@Component({
  selector: "app-c2",
  imports: [],
  templateUrl: "./c2.html",
  styleUrl: "./c2.css",
})
export class C2 implements OnInit {
  constructor(private notifyService: NotifyService) {}

  ngOnInit() {
    this.notifyService.onMsg().subscribe((msg) => {
      console.log("c2 got data %s", msg);
    });
  }
}
```

app.html

```html
<app-c1></app-c1>
<p>F12 看 console</p>
<app-c2></app-c2>
```

app.ts

```typescript
import { Component, signal } from "@angular/core";
import { C1 } from "./c1/c1";
import { C2 } from "./c2/c2";

@Component({
  selector: "app-root",
  imports: [C1, C2],
  templateUrl: "./app.html",
  styleUrl: "./app.css",
})
export class App {
  protected readonly title = signal("demo");
}
```

### 测试

```sh
http://localhost:4200/
```
