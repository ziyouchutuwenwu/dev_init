# httpoison

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
{:httpoison, "~> 2.0"},
{:jason, "~> 1.2"}
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

config :client_demo,
  httpoison_option: [
    hackney: [
      use_default_pool: false,
      insecure: true
    ],
    timeout: :infinity,
    checkout_timeout: :infinity,
    # proxy: {:socks5, '127.0.0.1', 1080},
    recv_timeout: :infinity
  ]
```

config/prod.exs

```elixir
import Config

config :logger,
  level: :warning

config :client_demo,
  base_url: "http://127.0.0.1:4000"

config :client_demo,
  httpoison_option: [
    hackney: [
      use_default_pool: false,
      insecure: true
    ],
    timeout: :infinity,
    checkout_timeout: :infinity,
    recv_timeout: :infinity
  ]
```

config/test.exs

```elixir
import Config

config :logger,
  level: :debug

config :client_demo,
  base_url: "http://127.0.0.1:4000"

config :client_demo,
  httpoison_option: [
    hackney: [
      use_default_pool: false,
      insecure: true
    ],
    timeout: :infinity,
    checkout_timeout: :infinity,
    recv_timeout: :infinity
  ]
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

  def get_httpoison_config() do
    Application.get_env(:client_demo, :httpoison_option)
  end
end
```

```elixir
defmodule ClientDemo do
  require Logger

  def get_demo do
    headers = []
    options = ConfigFetcher.get_httpoison_config()

    base_url = ConfigFetcher.get_base_url() |> URI.parse()

    url =
      base_url
      |> URI.append_path("/api/get-demo")
      |> URI.append_query("aaa=bbb")
      |> URI.to_string()

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.get(url, headers, options)

    Logger.debug(body)
  end

  def uri_demo do
    headers = []
    options = ConfigFetcher.get_httpoison_config()

    base_url = ConfigFetcher.get_base_url() |> URI.parse()
    url = base_url |> URI.append_path("/api/uri-demo/ppp") |> URI.to_string()

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.get(url, headers, options)

    Logger.debug(body)
  end

  def proxy_demo do
    url = "https://myip.ipip.net"

    headers = [
      {"User-Agent", "xxx"}
    ]

    options = [
      hackney: [
        use_default_pool: false,
        insecure: true
      ],
      timeout: :infinity,
      checkout_timeout: :infinity,
      recv_timeout: :infinity,
      proxy: {:socks5, ~c"127.0.0.1", 1080}
    ]

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.get(url, headers, options)

    Logger.debug(body)
  end

  def form_post_demo do
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    article_id = "11111"
    options = ConfigFetcher.get_httpoison_config()

    data = %{"id" => article_id}

    base_url = ConfigFetcher.get_base_url() |> URI.parse()
    url = base_url |> URI.append_path("/api/form-post") |> URI.to_string()

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      url
      |> HTTPoison.post({:form, data}, headers, options)

    Logger.debug(body)
  end

  def json_post_demo do
    headers = [
      {"Content-Type", "application/json"}
    ]

    json_data =
      Jason.encode!(%{
        aaa: "bbb"
      })

    options = ConfigFetcher.get_httpoison_config()

    base_url = ConfigFetcher.get_base_url() |> URI.parse()
    url = base_url |> URI.append_path("/api/json-post") |> URI.to_string()

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      url |> HTTPoison.post(json_data, headers, options)

    Logger.debug(body)
  end

  def file_upload_demo do
    {:ok, file_bin} = File.read("/home/mmc/downloads/aaa.bin")

    headers = []
    options = ConfigFetcher.get_httpoison_config()

    base_url = ConfigFetcher.get_base_url() |> URI.parse()
    url = base_url |> URI.append_path("/api/file-upload") |> URI.to_string()

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.put(url, file_bin, headers, options)

    Logger.debug(body)
  end
end
```

### 代理支持

```elixir
Application.put_env(:httpoison, :proxy, "http://127.0.0.1:8118")
```

或者

```sh
export HTTPOISON_PROXY=http://127.0.0.1:8118
```

### 类比 curl

```sh
curl 'http://127.0.0.1:4000/api/get-demo?aaa=bbb'
curl 'http://127.0.0.1:4000/api/uri-demo/ppp'
curl 'http://127.0.0.1:4000/api/form-post' -d 'abc=xyz'
curl 'http://127.0.0.1:4000/api/json-post' -H "Content-type: application/json" -d '{"phone": "18000011005","password": "xxxxx"}'
curl 'http://127.0.0.1:4000/api/file-upload' -T $HOME/downloads/aaa.bin
```
