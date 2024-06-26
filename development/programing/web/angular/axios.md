# axios

## 说明

需先设置跨域转发

## 例子

```sh
ng g c get-demo
ng g c form-post-demo
ng g c json-post-demo
ng g c download-demo
```

app.component.html

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

### get

get-demo.component.html

```html
<button (click)="demo()">get-demo</button>
```

get-demo.component.ts

```typescript
import { Component } from '@angular/core';
import axios from 'axios';

@Component({
  selector: 'app-get-demo',
  standalone: true,
  imports: [],
  templateUrl: './get-demo.component.html',
  styleUrl: './get-demo.component.css',
})
export class GetDemoComponent {
  ngOnInit(): void {
    console.log('/api/get-demo init');
  }

  demo() {
    const params = {
      username: 'mmc',
      password: '123456',
    };

    const request = axios.create({
      params: params,
    });
    request
      .get('/api/get-demo')
      .then((response) => {
        console.log('正确返回', response.data);
      })
      .catch((error) => {
        console.log('错误', error);
      });
  }
}
```

### form-post

form-post-demo.component.html

```html
<button (click)="demo()">form-post-demo</button>
```

form-post-demo.component.ts

```typescript
import { Component } from '@angular/core';
import axios from 'axios';

@Component({
  selector: 'app-form-post-demo',
  standalone: true,
  imports: [],
  templateUrl: './form-post-demo.component.html',
  styleUrl: './form-post-demo.component.css',
})
export class FormPostDemoComponent {
  ngOnInit(): void {
    console.log('/api/form-post-demo init');
  }

  demo() {
    const params = {
      username: 'mmc',
      password: '123456',
    };

    const request = axios.create({
      params: params,
    });
    request
      .post('/api/form-post-demo')
      .then((response) => {
        console.log('正确返回', response.data);
      })
      .catch((error) => {
        console.log('错误', error);
      });
  }
}
```

### json-post-demo

json-post-demo.component.html

```html
<button (click)="demo()">json-post-demo</button>
```

json-post-demo.component.ts

```typescript
import { Component } from '@angular/core';
import axios from 'axios';

@Component({
  selector: 'app-json-post-demo',
  standalone: true,
  imports: [],
  templateUrl: './json-post-demo.component.html',
  styleUrl: './json-post-demo.component.css',
})
export class JsonPostDemoComponent {
  ngOnInit(): void {
    console.log('/api/json-post-demo init');
  }

  demo() {
    const params = {
      username: 'mmc',
      password: '123456',
    };

    const request = axios.create({
      headers: {
        'Content-Type': 'application/json',
      },
    });
    request
      .post('/api/json-post-demo', params)
      .then((response) => {
        console.log('正确返回', response.data);
      })
      .catch((error) => {
        console.log('错误', error);
      });
  }
}
```

### download-demo

download-demo.component.html

```html
<button (click)="demo()">download-demo</button>
```

download-demo.component.ts

```typescript
import { Component } from "@angular/core";
import axios from "axios";

@Component({
  selector: "app-download-demo",
  standalone: true,
  imports: [],
  templateUrl: "./download-demo.component.html",
  styleUrl: "./download-demo.component.css",
})
export class DownloadDemoComponent {
  ngOnInit(): void {
    console.log("/api/download-demo init");
  }

  demo() {
    const url = "/api/download-demo";
    axios
      .get(url, { responseType: "blob" })
      .then((response) => {
        const blob = new Blob([response.data], { type: "application/zip" });
        const fileURL = window.URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = fileURL;
        link.download = "file.zip";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      })
      .catch((error) => console.error(error));
  }
}
```

### 忽略 ssl

```typescript
const agent = new https.Agent({
  rejectUnauthorized: false,
});
axios.get("https://xxx.com/xxx", { httpsAgent: agent });