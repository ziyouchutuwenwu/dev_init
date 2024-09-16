# req

## 说明

据说性能相对高

## 用法

### 服务端

创建项目

```sh
mix phx.new web_demo --no-assets --no-html --no-gettext --no-dashboard --no-live --no-mailer --no-ecto
```

router.ex

```elixir
defmodule WebDemoWeb.Router do
  use WebDemoWeb, :router
  WebDemoWeb.DemoController

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WebDemoWeb do
    pipe_through :api

    get "/get-demo", DemoController, :get_demo
    get "/uri-demo/:uri_arg", DemoController, :uri_demo
    post "/form-post", DemoController, :form_post_demo
    post "/json-post", DemoController, :json_post_demo
    put "/file-upload", DemoController, :file_upload_demo
  end
end
```

demo_controller.ex

```elixir
defmodule WebDemoWeb.DemoController do
  require Logger

  use WebDemoWeb, :controller

  def get_demo(conn, params) do
    %{"aaa" => value} = params
    text(conn, "value is #{value}")
  end

  def uri_demo(conn, params) do
    %{"uri_arg" => uri_arg_value} = params
    text(conn, "uri_arg uri_arg_value #{uri_arg_value}")
  end

  def form_post_demo(conn, params) do
    text(conn, inspect(params))
  end

  def json_post_demo(conn, _params) do
    json = Jason.encode!(conn.body_params)
    text(conn, json)
  end

  def file_upload_demo(conn, _params) do
    {:ok, file_bin, _conn } = Plug.Conn.read_body(conn)
    Logger.debug(inspect(file_bin))
    result = File.write("/tmp/saved_bin", file_bin)
    text(conn, inspect(result))
  end
end
```

### 客户端

创建项目

```sh
mix new client_demo
```

deps

```elixir
{:req, "~> 0.5.0"}
```

config/config.exs

```elixir
import Config

config :client_demo, mode: config_env()
import_config "#{config_env()}.exs"
```

config/dev.exs

```elixir
import Config

config :logger,
  level: :debug

config :client_demo,
  base_url: "http://127.0.0.1:4000"
```

config/prod.exs

```elixir
import Config

config :logger,
  level: :warning

config :client_demo,
  base_url: "http://127.0.0.1:4000"
```

config/test.exs

```elixir
import Config

config :logger,
  level: :debug

config :client_demo,
  base_url: "http://127.0.0.1:4000"
```

config/runtime.exs

```elixir
import Config

if config_env() === :prod do
  if System.get_env("BASE_URL") do
    config :client_demo,
      base_url: System.get_env("BASE_URL")
  end
end
```

```elixir
defmodule ConfigFetcher do
  def get_base_url() do
    Application.get_env(:client_demo, :base_url)
  end
end
```

```elixir
defmodule ClientDemo do
  require Logger

  def get_demo do
    headers = [
      {"User-Agent", "xxx"}
    ]

    base_url = ConfigFetcher.get_base_url() |> URI.parse()

    url =
      base_url
      |> URI.append_path("/api/get-demo")
      |> URI.append_query("aaa=bbb")
      |> URI.to_string()

    default_options = [
      headers: headers,
      retry: false,
      # 接收 http 数据的超时
      receive_timeout: :infinity,
      connect_options: [
        # 与服务器建立 tcp 连接的超时
        timeout: :infinity,
        transport_opts: [verify: :verify_none]
      ]
    ]

    options = default_options
    {:ok, resp} = url |> Req.get(options)
    body = resp.body

    Logger.debug(body)
  end

  def uri_demo do
    headers = [
      {"User-Agent", "xxx"}
    ]

    base_url = ConfigFetcher.get_base_url() |> URI.parse()
    url = base_url |> URI.append_path("/api/uri-demo/ppp") |> URI.to_string()

    default_options = [
      headers: headers,
      retry: false,
      # 接收 http 数据的超时
      receive_timeout: :infinity,
      connect_options: [
        # 与服务器建立 tcp 连接的超时
        timeout: :infinity,
        transport_opts: [verify: :verify_none]
      ]
    ]

    options = default_options
    {:ok, resp} = url |> Req.get(options)
    body = resp.body

    Logger.debug(body)
  end

  def proxy_demo do
    headers = [
      {"User-Agent", "xxx"}
    ]

    url = "https://myip.ipip.net"

    proxy_auth = {"proxy_user", "proxy_pass"}

    options = [
      headers: headers,
      retry: false,
      # 接收 http 数据的超时
      receive_timeout: :infinity,
      connect_options: [
        # 与服务器建立 tcp 连接的超时
        timeout: :infinity,
        transport_opts: [verify: :verify_none],
        proxy: {:http, "127.0.0.1", 8118, [proxy_auth: proxy_auth]}
      ]
    ]

    {:ok, resp} = url |> Req.get(options)
    body = resp.body

    Logger.debug(body)
  end

  def form_post_demo do
    headers = [
      {"User-Agent", "xxx"}
    ]

    data = [id: "11111"]

    base_url = ConfigFetcher.get_base_url() |> URI.parse()
    url = base_url |> URI.append_path("/api/form-post") |> URI.to_string()

    # options = [
    #   form: data,
    #   headers: headers,
    #   retry: false,
    #   # 接收 http 数据的超时
    #   receive_timeout: :infinity,
    #   connect_options: [
    #     # 与服务器建立 tcp 连接的超时
    #     timeout: :infinity,
    #     transport_opts: [verify: :verify_none]
    #   ]
    # ]

    default_options = [
      headers: headers,
      retry: false,
      # 接收 http 数据的超时
      receive_timeout: :infinity,
      connect_options: [
        # 与服务器建立 tcp 连接的超时
        timeout: :infinity,
        transport_opts: [verify: :verify_none]
      ]
    ]

    options = [{:form, data} | default_options]

    {:ok, resp} = url |> Req.post(options)
    body = resp.body

    Logger.debug(body)
  end

  def json_post_demo do
    headers = [
      {"User-Agent", "xxx"}
    ]

    json_data = %{
      aaa: "bbb"
    }

    base_url = ConfigFetcher.get_base_url() |> URI.parse()
    url = base_url |> URI.append_path("/api/json-post") |> URI.to_string()

    # options = [
    #   json: json_data,
    #   headers: headers,
    #   retry: false,
    #   # 接收 http 数据的超时
    #   receive_timeout: :infinity,
    #   connect_options: [
    #     # 与服务器建立 tcp 连接的超时
    #     timeout: :infinity,
    #     transport_opts: [verify: :verify_none]
    #   ]
    # ]

    default_options = [
      headers: headers,
      retry: false,
      # 接收 http 数据的超时
      receive_timeout: :infinity,
      connect_options: [
        # 与服务器建立 tcp 连接的超时
        timeout: :infinity,
        transport_opts: [verify: :verify_none]
      ]
    ]

    options = [{:json, json_data} | default_options]

    {:ok, resp} = url |> Req.post(options)
    body = resp.body

    Logger.debug(body)
  end

  def file_upload_demo do
    {:ok, file_bin} = File.read("/home/mmc/downloads/aaa.bin")

    headers = [
      {"User-Agent", "xxx"}
    ]

    base_url = ConfigFetcher.get_base_url() |> URI.parse()
    url = base_url |> URI.append_path("/api/file-upload") |> URI.to_string()

    # options = [
    #   body: file_bin,
    #   headers: headers,
    #   retry: false,
    #   # 接收 http 数据的超时
    #   receive_timeout: :infinity,
    #   connect_options: [
    #     # 与服务器建立 tcp 连接的超时
    #     timeout: :infinity,
    #     transport_opts: [verify: :verify_none]
    #   ]
    # ]

    default_options = [
      headers: headers,
      retry: false,
      # 接收 http 数据的超时
      receive_timeout: :infinity,
      connect_options: [
        # 与服务器建立 tcp 连接的超时
        timeout: :infinity,
        transport_opts: [verify: :verify_none]
      ]
    ]

    options = [{:body, file_bin} | default_options]

    {:ok, resp} = url |> Req.put(options)
    body = resp.body

    Logger.debug(body)
  end
end
```

### 类比 curl

```sh
curl 'http://127.0.0.1:4000/api/get-demo?aaa=bbb'
curl 'http://127.0.0.1:4000/api/uri-demo/ppp'
curl 'http://127.0.0.1:4000/api/form-post' -d 'abc=xyz'
curl 'http://127.0.0.1:4000/api/json-post' -H "Content-type: application/json" -d '{"phone": "18000011005","password": "xxxxx"}'
curl 'http://127.0.0.1:4000/api/file-upload' -T $HOME/downloads/aaa.bin
```
