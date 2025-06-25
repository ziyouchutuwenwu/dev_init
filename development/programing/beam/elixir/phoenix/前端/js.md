# js

## 例子

### 创建项目

```sh
mix phx.new web_demo --no-dashboard --no-live --no-mailer --no-ecto
```

### 路由

router.ex

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  get "/aaa", PageController, :aaa
  get "/bbb", PageController, :bbb
end
```

### controller

page_controller.ex

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  def aaa(conn, _params) do
    render(conn, :aaa)
  end

  def bbb(conn, _params) do
    render(conn, :bbb)
  end
end
```

### html

aaa.html.heex

```html
<button type="button" onclick="demo1.on_click()">click aaa</button>
```

bbb.html.heex

```html
<button type="button" onclick="demo2.on_click()">click bbb</button>
```

### assets 目录

assets 目录结构

```sh
assets
├── app.js
└── demo
    ├── aa.ts
    └── bb.ts
```

### js 代码

app.js

```typescript
import { DemoClass } from "./demo/aa";
import * as demo2 from "./demo/bb";

document.addEventListener("DOMContentLoaded", (event) => {
  if (window.location.pathname === "/aaa") {
    const demo1 = new DemoClass();
    window.demo1 = demo1;
    demo1.on_load();
  }
  if (window.location.pathname === "/bbb") {
    window.demo2 = demo2;
    demo2.on_load();
  }
});
```

aa.ts

```typescript
export class DemoClass {
  on_load(): void {
    console.log("on_load in DemoClass");
  }

  on_click(): void {
    console.log("on_click in DemoClass");
  }
}
```

bb.ts

```typescript
export function on_load(): void {
  console.log("on_load in bb");
}

export function on_click(): void {
  console.log("on_click in bb");
}
```
