# presence

## 说明

一般用来标记聊天室谁在线、谁正在打字，协同光标、游戏谁准备了之类的东西

## 例子

创建

```sh
mix phx.gen.presence
```

router.ex

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  get "/", PageController, :home
  live "/presence", PresenceLive
end
```

presence_live.ex

```elixir
defmodule WebDemoWeb.PresenceLive do
  use WebDemoWeb, :live_view
  alias WebDemoWeb.Presence
  require Logger

  @topic "xxx"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      WebDemoWeb.Endpoint.subscribe(@topic)
      {:ok, _} = Presence.track(self(), @topic, socket.id, %{status: "空闲"})
    end

    {:ok, assign(socket, users: Presence.list(@topic), last_action: "等待事件...")}
  end

  @impl true
  def handle_event("toggle_status", _params, socket) do
    Presence.update(self(), @topic, socket.id, fn meta ->
      new_status =
        if Map.get(meta, :status) == "空闲" do
          "忙碌"
        else
          "空闲"
        end

      Map.put(meta, :status, new_status)
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: payload}, socket) do
    Logger.debug(inspect(payload))
    joins = Map.get(payload, :joins, %{})
    leaves = Map.get(payload, :leaves, %{})

    action =
      cond do
        joins != %{} and leaves == %{} ->
          details =
            Enum.map(joins, fn {id, %{metas: [meta | _]}} ->
              "#{id} (状态: #{meta.status})"
            end)
            |> Enum.join(", ")

          "[上线] #{details}"

        joins == %{} and leaves != %{} ->
          "[下线] #{inspect(Map.keys(leaves))}"

        true ->
          details =
            Enum.map(joins, fn {id, %{metas: [new_meta | _]}} ->
              old_status = get_in(leaves, [id, :metas, Access.at(0), :status]) || "未知"
              "#{id} 从 [#{old_status}] 变为 [#{new_meta.status}]"
            end)
            |> Enum.join(", ")

          "[改状态] #{details}"
      end

    users =
      socket.assigns.users
      |> Map.drop(Map.keys(leaves))
      |> Map.merge(joins)

    {:noreply, assign(socket, users: users, last_action: action)}
  end
end
```

presence_live.html.heex

```html
<div class="max-w-md mx-auto py-10 space-y-4">
  <div class="flex items-center justify-between">
    <h1 class="text-xl font-bold">在线用户 ({map_size(@users)})</h1>
    <button phx-click="toggle_status" class="btn btn-sm btn-outline">
      切换我的状态
    </button>
  </div>

  <div class="p-2 text-xs font-mono bg-base-200 rounded">
    最新广播: {@last_action}
  </div>

  <ul class="divide-y divide-base-300 border rounded-lg">
    <li
      :for={{user_id, %{metas: [meta | _]}} <- @users}
      class="p-3 flex justify-between items-center text-sm"
    >
      <span class="font-mono">{user_id}</span>
      <div class="flex items-center gap-2">
        <span>{Map.get(meta, :status, "空闲")}</span>
        <span :if={user_id == @socket.id} class="text-xs text-primary font-semibold">(我)</span>
      </div>
    </li>
  </ul>
</div>
```
