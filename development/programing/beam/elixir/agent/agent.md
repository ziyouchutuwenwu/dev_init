# agent

agent 是基于 gen_server 实现的用于存储数据的进程

## 例子

```elixir
defmodule DemoAgent do
  use Agent

  def start_link(value \\ 0) do
    Agent.start_link(fn -> value end, name: __MODULE__)
  end

  def get do
    # Agent.get(__MODULE__, & &1)
    Agent.get(__MODULE__, fn value ->
      value
    end)
  end

  def increment do
    Agent.update(__MODULE__, fn value ->
      value + 1
    end)
  end
end
```

```elixir
defmodule UserAgent do
  require Logger

  def start_link(users \\ []) do
    Agent.start_link(fn -> users end, name: __MODULE__)
  end

  def add_user(user) do
    case user.id |> _found_user() do
      nil ->
        Agent.update(__MODULE__, fn users ->
          users |> Enum.concat([user])
        end)

      _ ->
        :existed
    end
  end

  def get_all() do
    Agent.get(__MODULE__, fn users ->
      users
    end)
  end

  def get_user(id) do
    id |> _found_user()
  end

  def update_user(id, update_map) do
    case id |> _found_user() do
      nil ->
        :no_user

      user ->
        Agent.update(__MODULE__, fn _users ->
          user |> Map.merge(update_map)
        end)
    end
  end

  defp _found_user(id) do
    found =
      Agent.get(__MODULE__, fn users ->
        Enum.filter(users, fn user ->
          user.id == id
        end)
      end)

    case found do
      [] ->
        nil

      result ->
        result |> List.first()
    end
  end
end
```
