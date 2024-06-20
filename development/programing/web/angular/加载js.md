# 加载 js

之前的版本支持在 html 直接写 `<script src="xxx">`，现在不支持了

## 纯加载

自定义指令

```sh
ng g d directive/LoadScript
```

load-script.directive.ts

```typescript
import { Directive, OnInit, Input } from "@angular/core";

@Directive({
  selector: "[appLoadScript]",
})
export class LoadScriptDirective implements OnInit {
  @Input("script") file: any;

  ngOnInit() {
    let node = document.createElement("script");
    node.src = this.file;
    node.type = "text/javascript";
    node.async = false;
    node.charset = "utf-8";
    document.getElementsByTagName("head")[0].appendChild(node);
  }
}
```

html

```html
<i appLoadScript [script]="'/assets/demo.js'"></i>
```

## 加载并调用

### 方法 1

aaa.js

```javascript
function demo1(name, age) {
  console.log(name, age);
}

function demo2(info) {
  alert(info);
}

export { demo1, demo2 };
```

ts 里面

```typescript
import { Component, OnInit } from "@angular/core";
import * as common from "../../assets/aaa";

@Component({
  selector: "app-demo",
  templateUrl: "./demo.component.html",
  styleUrls: ["./demo.component.css"],
})
export class DemoComponent implements OnInit {
  constructor() {}

  ngOnInit(): void {
    common.demo1("user", 11);
  }

  onClick() {
    common.demo2("my info");
  }
}
```

html

```html
<button (click)="onClick()">button</button>
```

### 方法 2

bbb.js

```javascript
alert("bbb");
```

ts 里面

```typescript
ngAfterViewInit() {
  import('../../assets/bbb.js');
}
```
