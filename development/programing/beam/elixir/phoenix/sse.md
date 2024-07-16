# sse

流式返回数据

## 例子

### 创建项目

```sh
mix phx.new web_demo --no-assets --no-html --no-gettext --no-dashboard --no-live --no-mailer --no-ecto
```

依赖

```elixir
{:httpoison, "~> 2.1"}
```

### 流式转发

流式转发依赖于本地流式服务，所以两个例子合并到一起

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

http_stream.ex

```elixir
defmodule HTTPStream do
  require Logger

  def get(url) do
    Stream.resource(
      fn ->
        _start_stream_request(url)
      end,
      fn resp ->
        _on_stream(resp)
      end,
      fn resp ->
        _on_stream_finish(resp)
      end
    )
  end

  def _start_stream_request(url) do
    Logger.debug("on stream start")

    HTTPoison.get!(
      url,
      %{},
      stream_to: self(),
      async: :once
    )
  end

  def _on_stream(%HTTPoison.AsyncResponse{id: id} = resp) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id, code: code} ->
        Logger.debug("on stream status: #{inspect(code)}")
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncHeaders{id: ^id, headers: headers} ->
        Logger.debug("on stream headers: #{inspect(headers, pretty: true)}")
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        Logger.debug("on chunk #{chunk}")
        HTTPoison.stream_next(resp)
        {[chunk], resp}

      %HTTPoison.AsyncEnd{id: ^id} ->
        {:halt, resp}
    end
  end

  def _on_stream_finish(resp) do
    Logger.debug("on stream finish")
    :hackney.stop_async(resp.id)
  end
end
```

#### controller

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
  require Logger
  alias Phoenix.PubSub
  use WebDemoWeb, :controller

  def stream_in_umbrella(conn, _params) do
    PubSub.subscribe(WebDemo.PubSub, "custom_data")

    # 启用分片消息
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> send_chunked(200)

    waiting_chunk(fn data ->
      Logger.debug("测试 #{inspect(data)}")
      chunk(conn, "分片数据 #{data}\n")
    end)

    conn
  end

  defp waiting_chunk(on_data_proc) do
    receive do
      {:plug_conn, :sent} ->
        # 在 put_resp_content_type 以后会收到这个消息
        waiting_chunk(on_data_proc)

      data ->
        on_data_proc.(data)
        waiting_chunk(on_data_proc)
    end
  end
end
```

#### 普通子项目

发送消息

```elixir
defmodule Demo do
  require Logger
  alias Phoenix.PubSub

  def send do
    Process.spawn(
      fn ->
        list = 1..30

        Enum.each(list, fn item ->
          PubSub.broadcast(WebDemo.PubSub, "custom_data", item |> Integer.to_string())
          Process.sleep(1000)
        end)
      end,
      []
    )
  end
end
```

#### 测试

```sh
iex -S mix phx.server
Demo.send
```

```sh
curl http://127.0.0.1:4000/api/stream-in-umbrella
```
