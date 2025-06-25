# react

## 说明

[参考链接](https://bpaulino.com/entries/modern-webapps-with-elixir-phoenix-typescript-react)

基于 vite 的 vue 和 react 一样集成

## 步骤

### 创建项目

创建 phoenix 项目

```sh
mix phx.new web_demo --no-dashboard --no-live --no-mailer --no-ecto
```

创建前端项目

```sh
cd web_demo
npm init vite@latest frontend -- --template react-ts
```

运行

```sh
cd frontend
npm install
npm run dev
```

### vite 配置

frontend/vite.config.ts

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],

  // 前端请求转发
  server: {
    proxy: {
      "/api": {
        target: "http://localhost:4000",
        secure: false,
        ws: true,
      },
    },
  },

  // 发布路径
  base: process.env.NODE_ENV === "production" ? "/webapp/" : "/",
});
```

增加 process 的类型定义

```sh
npm i --save-dev @types/node
```

### 创建 task

lib/mix/tasks/webapp.ex

```elixir
defmodule Mix.Tasks.Webapp do
  use Mix.Task
  require Logger

  @public_path "./priv/static/webapp"

  @shortdoc "Compile and bundle frontend for production"
  @spec run(any()) :: :ok
  def run(_) do
    Logger.info("📦 - Installing NPM packages")
    System.cmd("npm", ["install", "--quiet"], cd: "./frontend")

    Logger.info("⚙️  - Compiling frontend")
    System.cmd("npm", ["run", "build"], cd: "./frontend")

    Logger.info("🚛 - Moving dist folder to Phoenix at #{@public_path}")

    System.cmd("rm", ["-rf", @public_path])
    System.cmd("cp", ["-R", "./frontend/dist", @public_path])
    System.cmd("rm", ["-rf", "./frontend/dist"])

    Logger.info("⚛️  - frontend ready.")
  end
end
```

执行

```sh
mix webapp
```

在 priv/static/webapp/index.html 里面，能看到引用的资源，都有 /webapp/assets 前缀

### 修改静态路径

endpoint.ex

```elixir
plug Plug.Static,
  at: "/",
  from: :web_demo,
  gzip: false,
  only: WebDemoWeb.static_paths()
```

```elixir
def static_paths, do: ~w(webapp assets fonts images favicon.ico robots.txt)
```

### controller

webapp_controller.ex

```elixir
defmodule WebDemoWeb.WebappController do
  use WebDemoWeb, :controller

  def index(conn, _params) do
    conn
    |> send_resp(200, render_app())
  end

  # 客户把读取的内容保存到 ets 里面
  defp render_app() do
    Application.app_dir(:web_demo, "priv/static/webapp/index.html")
    |> File.read!()
  end
end
```

### 路由

```elixir
scope "/app", WebDemoWeb do
  get "/", WebappController, :index
  get "/*any", WebappController, :index
end
```
