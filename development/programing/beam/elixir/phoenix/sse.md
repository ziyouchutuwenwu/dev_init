# sse

流式返回数据

## 例子

### 创建项目

```sh
mix phx.new web_demo --no-assets --no-html --no-gettext --no-dashboard --no-live --no-mailer --no-ecto
```

依赖

```elixir
{:req, "~> 0.5.9"},
```

### 流式转发

流式转发依赖于本地流式服务，所以两个例子合并到一起

#### app

启用 finch

```elixir
defmodule WebDemo.Application do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("in app start")

    children = [
      {
        Finch,
        name: ConfigedFinch,
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

#### router

router.ex

```elixir
defmodule WebDemoWeb.Router do
  use WebDemoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WebDemoWeb do
    pipe_through :api

    get "/stream-wrapper", StreamController, :on_stream_wrapper
    get "/stream", StreamController, :on_stream
  end
end
```

#### 流式包装

finch_http_stream.ex

```elixir
defmodule FinchHTTPStream do
  require Logger

  def get(url) do
    Stream.resource(
      fn -> _start_stream_request(url) end,
      fn state -> _on_stream(state) end,
      fn state -> _on_stream_finish(state) end
    )
  end

  def _start_stream_request(url) do
    Logger.debug("on stream start")

    # 主进程收消息，task 用来干活
    parent_pid = self()

    Task.start_link(fn ->
      request = Finch.build(:get, url)

      Finch.stream(request, ConfigedFinch, nil, fn
        {:status, status}, _acc ->
          Logger.debug("{:status, #{status}}")
          {:cont, nil}

        {:headers, headers}, _acc ->
          Logger.debug("{:headers, #{inspect(headers)}}")
          {:cont, nil}

        {:data, chunk}, _acc ->
          Logger.debug("{:data, chunk}")
          send(parent_pid, {:sse_event, chunk})
          {:cont, nil}

        # 这里无法触发
        :done, _acc ->
          Logger.debug(":done, _acc")
          send(parent_pid, {:sse_finished, :done})
          {:halt, nil}

        {:error, reason}, _acc ->
          Logger.error(" {:error, reason} #{inspect(reason)}")
          send(parent_pid, {:sse_error, reason})
          {:halt, nil}
      end)

      # 因为 :done 无法触发，所以手动 send finish 消息
      send(parent_pid, {:sse_finished, :done})
    end)

    parent_pid
  end

  def _on_stream(pid) do
    receive do
      {:sse_event, chunk} ->
        Logger.info("on sse_event: #{inspect(chunk)}")
        {[chunk], pid}

      {:sse_finished, _} ->
        Logger.info("on sse_finished")
        {:halt, pid}

      {:sse_error, reason} ->
        Logger.error("on sse_error: #{inspect(reason)}")
        {:halt, pid}
    after
      20000 ->
        Logger.info("on sse_timeout")
        {:halt, pid}
    end
  end

  def _on_stream_finish(_pid) do
    Logger.debug("on stream finish")
  end
end
```

req_http_stream.ex

```elixir
defmodule ReqHTTPStream do
  require Logger

  def get(url) do
    Stream.resource(
      fn -> _start_stream_request(url) end,
      fn state -> _on_stream(state) end,
      fn state -> _on_stream_finish(state) end
    )
  end

  def _start_stream_request(url) do
    Logger.debug("on stream start")

    # 主进程收消息，task 用来干活
    parent_pid = self()

    Task.start(fn ->
      try do
        default_options = [
          retry: false,
          receive_timeout: :infinity,
          finch: ConfigedFinch
        ]

        options =
          [
            into: fn {:data, data}, {req, resp} ->
              Logger.debug("on chunk in options #{inspect(data)}")
              send(parent_pid, {:sse_event, data})
              {:cont, {req, resp}}
            end
          ]
          |> Keyword.merge(default_options)

        Req.get!(url, options)
        send(parent_pid, {:sse_finished, :done})
      rescue
        exception ->
          send(parent_pid, {:sse_error, exception})
      end
    end)

    parent_pid
  end

  def _on_stream(pid) do
    receive do
      {:sse_event, chunk_data} ->
        Logger.info("on sse_event: #{inspect(chunk_data)}")
        {[chunk_data], pid}

      {:sse_finished, _} ->
        Logger.info("on sse_finished")
        {:halt, pid}

      {:sse_error, reason} ->
        Logger.error("on sse_error: #{inspect(reason)}")
        {:halt, pid}
    after
      50000 ->
        Logger.info("on sse_timeout")
        {[], pid}
    end
  end

  def _on_stream_finish(_pid) do
    Logger.debug("on stream finish")
  end
end
```

或者

```elixir
defmodule ReqHTTPStream do
  require Logger

  def get(url) do
    default_options = [
      retry: false,
      receive_timeout: :infinity,
      finch: ConfigedFinch
    ]

    options = [into: :self] |> Keyword.merge(default_options)

    resp = url |> Req.get!(options)
    resp.body
  end

  def debug(url) do
    url |> Req.get!(into: IO.stream())
  end
end
```

#### controller

stream_controller.ex

```elixir
defmodule WebDemoWeb.StreamController do
  use WebDemoWeb, :controller

  # http://127.0.0.1:4000/api/stream
  def on_stream(conn, _params) do
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> send_chunked(200)

    _send_stream_data(conn)
  end

  defp _send_stream_data(conn) do
    Enum.each(1..10, fn data ->
      chunk(conn, "分片数据 #{data}\n")
      Process.sleep(1000)
    end)

    conn
  end

  # http://127.0.0.1:4000/api/stream-wrapper
  def on_stream_wrapper(conn, _params) do
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> send_chunked(200)

    url = "http://127.0.0.1:4000/api/stream"

    # 这里换成 ReqHTTPStream
    HTTPStream.get(url)
    |> Enum.reduce_while(conn, fn chunk, conn ->
      case Plug.Conn.chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end)

    conn
  end
end
```

#### 验证

```sh
mix phx.server
curl http://127.0.0.1:4000/api/stream
curl http://127.0.0.1:4000/api/stream-wrapper
```

### umbrella 项目

#### web 子项目

router

```elixir
defmodule WebDemoWeb.Router do
  use WebDemoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # curl http://127.0.0.1:4000/api/stream-in-umbrella
  scope "/api", WebDemoWeb do
    pipe_through :api
    get "/stream-in-umbrella", StreamController, :stream_in_umbrella
  end
end
```

controller 内，订阅消息

```elixir
defmodule WebDemoWeb.StreamController do
  use WebDemoWeb, :controller
  alias Phoenix.PubSub
  require Logger

  def stream_in_umbrella(conn, _params) do
    Logger.debug("当前 pid #{inspect(self())}")
    PubSub.subscribe(WebDemo.PubSub, "custom_data")

    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> send_chunked(200)

    data_waiting(conn, &on_data/2)
    chunk(conn, "")

    PubSub.unsubscribe(WebDemo.PubSub, "custom_data")
    conn
  end

  defp on_data(conn, data) do
    Logger.debug("测试 #{inspect(data)}")
    chunk(conn, "分片数据 #{data}\n")
  end

  defp data_waiting(conn, on_data_proc) do
    receive do
      # send_chunked 以后会收到这个消息
      {:plug_conn, :sent} ->
        data_waiting(conn, on_data_proc)

      :done ->
        Logger.debug("收到结束信号，终止连接")

      # 其它消息，这里就是订阅的消息
      data ->
        on_data_proc.(conn, data)
        data_waiting(conn, on_data_proc)
    end
  end
end
```

#### 普通子项目

给 web_demo 发送消息

```elixir
defmodule Demo do
  alias Phoenix.PubSub
  require Logger

  def send do
    Process.spawn(
      fn ->
        list = 1..5

        Enum.each(list, fn item ->
          PubSub.broadcast(WebDemo.PubSub, "custom_data", item |> Integer.to_string())
          Process.sleep(1000)
        end)

        PubSub.broadcast(WebDemo.PubSub, "custom_data", :done)
      end,
      []
    )
  end
end
```

#### 测试

```sh
iex -S mix phx.server
```

```sh
curl http://127.0.0.1:4000/api/stream-in-umbrella
```

```elixir
Demo.send
```
