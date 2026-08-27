# http

## 说明

需先设置跨域转发，用的 axios

## 例子

准备工作

```sh
ng g c get-demo
npm install axios

ng g c form-post-demo
ng g c json-post-demo
ng g c download-demo
```

app.html

```html
<div>
  <app-get-demo></app-get-demo>
</div>

<div>
  <app-form-post-demo></app-form-post-demo>
</div>

<div>
  <app-json-post-demo></app-json-post-demo>
</div>

<div>
  <app-download-demo></app-download-demo>
</div>
```

### axios 配置

src/axios/wrapper.ts

```typescript
import axios, { AxiosInstance } from "axios";

class AxiosWrapper {
  static _instance: AxiosInstance;

  constructor() {
    if (!AxiosWrapper._instance) {
      AxiosWrapper._instance = axios.create({
        timeout: 1000,
      });
    }
  }

  static getInstance(): AxiosInstance {
    if (!AxiosWrapper._instance) {
      new AxiosWrapper();
    }
    return AxiosWrapper._instance;
  }
}

export const axioShareInstance = AxiosWrapper.getInstance();
```

### get

get-demo.html

```html
<button (click)="demo()">get-demo</button>
```

get-demo.ts

```typescript
import { Component } from "@angular/core";
import { axioShareInstance } from "../../axios/wrapper";

@Component({
  selector: "app-get-demo",
  imports: [],
  templateUrl: "./get-demo.html",
  styleUrl: "./get-demo.css",
})
export class GetDemo {
  ngOnInit(): void {
    console.log("/api/get-demo init");
  }

  demo() {
    const dataMap = {
      username: "mmc",
      password: "123456",
    };
    const request = axioShareInstance;
    request
      .get("/api/get-demo", { params: dataMap })
      .then((response) => {
        console.log("正确返回", response.data);
      })
      .catch((error) => {
        console.log("错误", error);
      });
  }
}
```

### form-post

form-post-demo.html

```html
<button (click)="demo()">form-post-demo</button>
```

form-post-demo.ts

```typescript
import { Component } from "@angular/core";
import { axioShareInstance } from "../../axios/wrapper";

@Component({
  selector: "app-form-post-demo",
  imports: [],
  templateUrl: "./form-post-demo.html",
  styleUrl: "./form-post-demo.css",
})
export class FormPostDemo {
  ngOnInit(): void {
    console.log("/api/form-post-demo init");
  }

  demo() {
    const dataMap = {
      username: "mmc",
      password: "123456",
    };

    const request = axioShareInstance;
    request.defaults.headers["Content-Type"] = "application/x-www-form-urlencoded";
    request
      .post("/api/form-post-demo", { params: dataMap })
      .then((response) => {
        console.log("正确返回", response.data);
      })
      .catch((error) => {
        console.log("错误", error);
      });
  }
}
```

### json-post-demo

json-post-demo.html

```html
<button (click)="demo()">json-post-demo</button>
```

json-post-demo.ts

```typescript
import { Component } from "@angular/core";
import { axioShareInstance } from "../../axios/wrapper";

@Component({
  selector: "app-json-post-demo",
  imports: [],
  templateUrl: "./json-post-demo.html",
  styleUrl: "./json-post-demo.css",
})
export class JsonPostDemo {
  ngOnInit(): void {
    console.log("/api/json-post-demo init");
  }

  demo() {
    const dataMap = {
      username: "mmc",
      password: "123456",
    };

    const request = axioShareInstance;
    request.defaults.headers["Content-Type"] = "application/json";
    request
      .post("/api/json-post-demo", { params: dataMap })
      .then((response) => {
        console.log("正确返回", response.data);
      })
      .catch((error) => {
        console.log("错误", error);
      });
  }
}
```

### download-demo

download-demo.html

```html
<button (click)="demo()">download-demo</button>
```

download-demo.ts

```typescript
import { Component } from "@angular/core";
import { axioShareInstance } from "../../axios/wrapper";

@Component({
  selector: "app-download-demo",
  imports: [],
  templateUrl: "./download-demo.html",
  styleUrl: "./download-demo.css",
})
export class DownloadDemo {
  ngOnInit(): void {
    console.log("/api/download-demo init");
  }

  demo() {
    const dataMap = {};
    const request = axioShareInstance;
    request
      .get("/api/download-demo", { params: dataMap, responseType: "blob" })
      .then((response) => {
        const blob = new Blob([response.data], {
          // 任意的二进制数据
          type: "application/octet-stream",
        });
        const fileURL = window.URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = fileURL;
        link.download = "file.zip";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      })
      .catch((error) => {
        console.log("错误", error);
      });
  }
}
```
