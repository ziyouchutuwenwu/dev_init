# chrome 插件

## 说明

支持 popup, options, 右键菜单

## 注意

src/styles.css 不要有任何代码，否则 build 以后，会在 index.html 里面引入 css 代码，chrome 不允许

集成 tailwindcss 的时候，在需要的 css 页面里面 import

## 步骤

### 创建

不要选择 ssr

```sh
ng new xxx
```

### 依赖

```sh
npm install --save-dev copyfiles
```

### 配置

chrome_extra/config/manifest.json

```json
{
  "manifest_version": 3,
  "name": "xxx",
  "version": "1.0",
  "action": {
    "default_popup": "index.html#popup",
    "default_icon": {
      "16": "assets/icon.png"
    }
  },
  "options_page": "index.html#options",
  "permissions": ["contextMenus", "activeTab", "scripting"],
  "background": {
    "service_worker": "background.js"
  },
  "host_permissions": ["<all_urls>"]
}
```

chrome_extra/config/background.js

```js
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "my_menu",
    title: "右键菜单示例",
    contexts: ["all"],
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "my_menu") {
    chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: () => {
        const url = chrome.runtime.getURL("index.html#options");
        alert("右键菜单 " + url);

        chrome.tabs.create({
          url: url,
        });
      },
    });
  }
});
```

chrome_extra/task/extra_copy.js

```js
const { execSync } = require("child_process");
const pkg = require("../../package.json");

const projectName = pkg.name;
const target = `dist/${projectName}/browser`;

// 构建 copyfiles 命令
const cmd = ["copyfiles", "-u 2", "chrome_extra/config/*", "public/assets/*", target].join(" ");

console.log("running:", cmd);
execSync(cmd, { stdio: "inherit" });
```

assets 目录位置

```sh
public/assets
```

package.json

```sh
"chrome_extra_copy": "node chrome_extra/task/extra_copy.js",
"chrome_build": "ng build --configuration production && npm run chrome_extra_copy",
```

### 路由

src/app/app.config.ts

```ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners, provideZoneChangeDetection } from "@angular/core";
import { provideRouter, withHashLocation } from "@angular/router";

import { routes } from "./app.routes";

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    // provideRouter(routes)
    // 启用 hash 路由
    provideRouter(routes, withHashLocation()),
  ],
};
```

src/app/app.routes.ts

```ts
import { Routes } from '@angular/router';
import { Main as PopupMain } from './popup/main/main';
import { Main as OptionsMain } from './options/main/main';

export const routes: Routes = [
  { path: '', redirectTo: 'popup', pathMatch: 'full' },
  { path: 'popup', component: PopupMain },
  { path: 'options', component: OptionsMain },
];
```

### html

src/index.html

```html
<!DOCTYPE html>
<!-- <html lang="zh"> -->
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>xxx</title>
    <base href="/" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" type="image/x-icon" href="favicon.ico" />
  </head>
  <body>
    <app-root></app-root>
  </body>
</html>
```

src/app/app.html

```html
<router-outlet></router-outlet>
```

### popup

```sh
ng g c popup/main
```

src/app/popup/main/main.html

```html
<div class="fixed-sizer">
  <span class="text-center block">这是 popup 组件</span>
</div>
```

src/app/popup/main/main.css

```css
@import "tailwindcss";

.fixed-sizer {
  width: 400px;
  min-width: 400px;
  height: 500px;
  min-height: 500px;
  margin: 0;
  padding: 10px;
  overflow: auto;
  box-sizing: border-box;
}
```

### options

```sh
ng g c options/main
```

src/app/options/main/main.html

```html
<p>这是 options 组件</p>
```

### 打包

```sh
npm run chrome_build
```
