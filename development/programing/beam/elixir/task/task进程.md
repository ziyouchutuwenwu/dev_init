# task 进程

task 进程一般用于执行一项特定操作的进程，通常与其他进程很少或根本没有通信。

## 例子

```elixir
defmodule MyTask do
  require Logger

  def start_link(domain_or_ip, port) do
    Task.start_link(__MODULE__, :run, [domain_or_ip, port])
  end

  def run(domain_or_ip, port) do
    ip = domain_or_ip |> _get_ip |> String.to_charlist()

    case :gen_tcp.connect(ip, port, [], 2000) do
      {:ok, socket} ->
        :gen_tcp.close(socket)

      _ ->
        Logger.error("#{domain_or_ip}:#{port} 不通")
    end
  end

  defp _get_ip(domain) do
    host = domain |> String.to_charlist()

    case :inet.getaddr(host, :inet) do
      {:ok, ip_addr} ->
        ip_addr |> Tuple.to_list() |> Enum.join(".")

      {:error, reason} ->
        Logger.error("域名 #{domain} 解析失败，原因 #{reason}")
        ""
    end
  end
end
```
