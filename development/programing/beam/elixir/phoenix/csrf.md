# csrf

## 说明

防止跨站伪造的请求, 对于 POST, PUT, DELETE 请求生效

### 请求字段

| 请求方式              | 位置     | 字段         |
| --------------------- | -------- | ------------ |
| x-www-form-urlencoded | header   | x-csrf-token |
| application/json      | 普通参数 | \_csrf_token |
| application/json      | header   | x-csrf-token |

## 例子

### 创建项目

```sh
mix phx.new web_demo --no-assets --no-html --no-gettext --no-dashboard --no-live --no-mailer --no-ecto
```

### 纯接口

router.ex

```elixir
defmodule WebDemoWeb.Router do
  use WebDemoWeb, :router

  # 独立出来
  pipeline :csrf do
    # fetch_session 不能忽略
    plug :fetch_session
    plug :protect_from_forgery

    # 用于防止 xss, 这里可以不用
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WebDemoWeb do
    # pipe_through [:api, :csrf]

    pipe_through :api
    pipe_through :csrf

    get "/get", DemoController, :get
    get "/delete", DemoController, :delete
    post "/check", DemoController, :check
  end
end
```

demo_controller.ex

```elixir
defmodule WebDemoWeb.DemoController do
  use WebDemoWeb, :controller

  def get(conn, _assigns) do
    json(conn, %{csrf_token: get_csrf_token()})
  end

  def delete(conn, _assigns) do
    json(conn, %{csrf_token: delete_csrf_token()})
  end

  # 非 get 请求, 需要另外加字段, 否则返回 403
  def check(conn, _assigns) do
    json(conn, %{msg: "check"})
  end
end
```

### 前端代码

html

```html
<div>token {{ this.csrf_token }}</div>
<form>
  <input type="text" name="username" [(ngModel)]="this.username" />
  <input type="password" name="password" [(ngModel)]="this.password" />
  <button (click)="formPost()">formPost</button>
</form>

<form>
  <input type="text" name="username" [(ngModel)]="this.username" />
  <input type="password" name="password" [(ngModel)]="this.password" />
  <button (click)="jsonPost()">jsonPost</button>
</form>
```

```typescript
import { Component } from "@angular/core";
import { FormsModule } from "@angular/forms";
import { RouterOutlet } from "@angular/router";
import axios from "axios";

@Component({
  selector: "app-root",
  standalone: true,
  imports: [RouterOutlet, FormsModule],
  templateUrl: "./app.component.html",
  styleUrl: "./app.component.css",
})
export class AppComponent {
  username: string = "";
  password: string = "";
  csrf_token: string = "";

  ngOnInit() {
    const dataMap = {};
    const request = this.getAxiosInstance();
    request
      .get("/api/get", dataMap)
      .then((response) => {
        console.log("正确返回", response.data.csrf_token);
        this.csrf_token = response.data.csrf_token;
      })
      .catch((error) => {
        console.log("错误", error);
      });
  }

  formPost() {
    const dataMap = {
      username: this.username,
      password: this.password,
    };

    const request = this.getAxiosInstance();
    request.defaults.headers["x-csrf-token"] = this.csrf_token;
    request.defaults.headers["Content-Type"] = "application/x-www-form-urlencoded";

    request
      .post("/api/check", dataMap)
      .then((response) => {
        console.log("正确返回", response.data);
      })
      .catch((error) => {
        console.log("错误", error);
      });
  }

  jsonPost() {
    const dataMap = {
      username: this.username,
      password: this.password,
      // _csrf_token: this.csrf_token,
    };

    const request = this.getAxiosInstance();
    request.defaults.headers["x-csrf-token"] = this.csrf_token;
    request.defaults.headers["Content-Type"] = "application/json";

    request
      .post("/api/check", dataMap)
      .then((response) => {
        console.log("正确返回", response.data);
      })
      .catch((error) => {
        console.log("错误", error);
      });
  }

  getAxiosInstance() {
    const axiosInstance = axios.create({
      timeout: 3000,
      headers: {
        "x-csrf-token": this.csrf_token,
      },
    });

    return axiosInstance;
  }
}
```
