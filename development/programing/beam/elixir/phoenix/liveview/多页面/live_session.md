# live_session

## 说明

一个 live_session，内部多个 liveview 页面

## 例子

router.ex

```elixir
live_session :session_name1, on_mount: [WebDemoWeb.LiveDemo1Hook] do
  live "/page1", Page1Live, :index
  live "/page2", Page2Live, :index
end
```

page_store.ex

```elixir
defmodule WebDemo.PageStore do
  use Agent

  def start_link(_opts \\ []) do
    Agent.start_link(
      fn ->
        %{aaa: 0, bbb: 0}
      end,
      name: __MODULE__
    )
  end

  def get(key) do
    ensure_started()

    Agent.get(__MODULE__, fn data ->
      Map.get(data, key, 0)
    end)
  end

  def put(key, value) do
    ensure_started()

    Agent.update(__MODULE__, fn data ->
      Map.put(data, key, value)
    end)
  end

  def reset do
    ensure_started()

    Agent.update(__MODULE__, fn _data ->
      %{aaa: 0, bbb: 0}
    end)
  end

  defp ensure_started do
    case Process.whereis(__MODULE__) do
      nil ->
        case start_link([]) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
        end

      _pid ->
        :ok
    end
  end
end
```

live_demo1_hook.ex

```elixir
defmodule WebDemoWeb.LiveDemo1Hook do
  import Phoenix.Component

  # session下每个liveview 都会被触发
  # 在mount之前执行
  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> assign(:aaa, WebDemo.PageStore.get(:aaa))
      |> assign(:bbb, WebDemo.PageStore.get(:bbb))

    {:cont, socket}
  end
end
```

page1_live.ex

```elixir
defmodule WebDemoWeb.Page1Live do
  use WebDemoWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "页面 1")
      |> assign_new(:aaa, fn ->
        WebDemo.PageStore.get(:aaa)
      end)

    {:ok, socket}
  end

  def handle_event("inc", _params, socket) do
    new_aaa = (socket.assigns[:aaa] || 0) + 1
    WebDemo.PageStore.put(:aaa, new_aaa)
    {:noreply, assign(socket, :aaa, new_aaa)}
  end

  def handle_event("dec", _params, socket) do
    new_aaa = (socket.assigns[:aaa] || 0) - 1
    WebDemo.PageStore.put(:aaa, new_aaa)
    {:noreply, assign(socket, :aaa, new_aaa)}
  end
end
```

page1_live.html.heex

```html
<Layouts.app flash={@flash}>
  <div class="max-w-md mx-auto space-y-6">
    <nav id="live-session-nav" class="flex gap-2">
      <.link navigate={~p"/page1"} id="nav-page1" class="btn btn-sm btn-primary">Page 1</.link>
      <.link navigate={~p"/page2"} id="nav-page2" class="btn btn-sm btn-ghost">Page 2</.link>
    </nav>

    <div class="space-y-4">
      <h1 class="text-xl font-bold">Page 1</h1>

      <div class="flex items-center gap-3">
        <.button id="dec-btn" phx-click="dec">-</.button>
        <span id="value" class="font-mono text-xl font-bold">{@aaa}</span>
        <.button id="inc-btn" phx-click="inc">+</.button>
      </div>
    </div>
  </div>
</Layouts.app>
```

page2_live.ex

```elixir
defmodule WebDemoWeb.Page2Live do
  use WebDemoWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "页面 2")
      |> assign_new(:bbb, fn -> WebDemo.PageStore.get(:bbb) end)

    {:ok, socket}
  end

  def handle_event("inc", _params, socket) do
    new_bbb = (socket.assigns[:bbb] || 0) + 1
    WebDemo.PageStore.put(:bbb, new_bbb)
    {:noreply, assign(socket, :bbb, new_bbb)}
  end

  def handle_event("dec", _params, socket) do
    new_bbb = (socket.assigns[:bbb] || 0) - 1
    WebDemo.PageStore.put(:bbb, new_bbb)
    {:noreply, assign(socket, :bbb, new_bbb)}
  end
end
```

page2_live.html.heex

```html
<Layouts.app flash={@flash}>
  <div class="max-w-md mx-auto space-y-6">
    <nav id="live-session-nav" class="flex gap-2">
      <.link navigate={~p"/page1"} id="nav-page1" class="btn btn-sm btn-ghost">Page 1</.link>
      <.link navigate={~p"/page2"} id="nav-page2" class="btn btn-sm btn-primary">Page 2</.link>
    </nav>

    <div class="space-y-4">
      <h1 class="text-xl font-bold">Page 2</h1>

      <div class="flex items-center gap-3">
        <.button id="dec-btn" phx-click="dec">-</.button>
        <span id="value" class="font-mono text-xl font-bold">{@bbb}</span>
        <.button id="inc-btn" phx-click="inc">+</.button>
      </div>
    </div>
  </div>
</Layouts.app>
```
