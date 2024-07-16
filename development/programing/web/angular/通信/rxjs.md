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

c1.component.ts

```typescript
import { Component, OnInit } from "@angular/core";
import { NotifyService } from "../notify.service";

@Component({
  selector: "app-c1",
  standalone: true,
  imports: [],
  templateUrl: "./c1.component.html",
  styleUrl: "./c1.component.css",
})
export class C1Component implements OnInit {
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

c1.component.html

```html
<button (click)="send()">发送</button>
```

c2.component.ts

```typescript
import { Component, OnInit } from "@angular/core";
import { NotifyService } from "../notify.service";

@Component({
  selector: "app-c2",
  standalone: true,
  imports: [],
  templateUrl: "./c2.component.html",
  styleUrl: "./c2.component.css",
})
export class C2Component implements OnInit {
  constructor(private notifyService: NotifyService) {}

  ngOnInit() {
    this.notifyService.onMsg().subscribe((msg) => {
      console.log("c2 got data %s", msg);
    });
  }
}
```

app.component.html

```html
<app-c1></app-c1>
<p>F12 看 console</p>
<app-c2></app-c2>
```

app.component.ts

```typescript
import { Component } from "@angular/core";
import { RouterOutlet } from "@angular/router";
import { C1Component } from "./c1/c1.component";
import { C2Component } from "./c2/c2.component";

@Component({
  selector: "app-root",
  standalone: true,
  imports: [RouterOutlet, C1Component, C2Component],
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.css",
})
export class AppComponent {
  title = "demo";
}
```

### 测试

```sh
http://localhost:4200/
```
