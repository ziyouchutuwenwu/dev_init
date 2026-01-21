# tcp 转发

## 说明

局域网转发

## 代码

```elixir
defmodule TCPForwarder do
  require Logger

  def start(listen_port, forward_to: {target_host, target_port}) do
    Task.start_link(fn ->
      do_start(listen_port, target_host, target_port)
    end)
  end

  defp do_start(listen_port, target_host, target_port) do
    {:ok, listen_socket} =
      :gen_tcp.listen(listen_port, [
        :binary,
        active: false,
        reuseaddr: true,
        packet: :raw
      ])

    Logger.info(
      "tcp forwarder started on port #{listen_port}, forwarding to #{target_host}:#{target_port}"
    )

    accept_connections(listen_socket, target_host, target_port)
  end

  defp accept_connections(listen_socket, target_host, target_port) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)

    Task.start_link(fn ->
      handle_connection(client_socket, target_host, target_port)
    end)

    accept_connections(listen_socket, target_host, target_port)
  end

  defp handle_connection(client_socket, target_host, target_port) do
    {:ok, target_socket} =
      :gen_tcp.connect(
        to_charlist(target_host),
        target_port,
        [
          :binary,
          active: false,
          packet: :raw
        ]
      )

    forwarder_pid = self()

    Task.start_link(fn ->
      forward_data(client_socket, target_socket, "client -> target", forwarder_pid)
    end)

    Task.start_link(fn ->
      forward_data(target_socket, client_socket, "target -> client", forwarder_pid)
    end)

    receive do
      {:forwarder_done, _reason} -> :ok
    end

    :gen_tcp.close(client_socket)
    :gen_tcp.close(target_socket)
  end

  defp forward_data(source, destination, direction, forwarder_pid) do
    case :gen_tcp.recv(source, 0) do
      {:ok, data} ->
        Logger.debug("#{direction}: #{byte_size(data)} bytes")
        :gen_tcp.send(destination, data)
        forward_data(source, destination, direction, forwarder_pid)

      {:error, reason} ->
        Logger.info("#{direction} connection closed: #{inspect(reason)}")
        send(forwarder_pid, {:forwarder_done, reason})
    end
  end
end
```

调用

```elixir
TCPForwarder.start(7777, forward_to: {"127.0.0.1", 22})
```
