# port

## 说明

监控 port 进程的启停，推荐

和 port 收发数据，最好带上包头 `{:packet, 2}`

```sh
{:spawn, command}
  通过默认 shell, 关闭的时候，可能导致僵尸进程

{:spawn_executable, path}
  不经过 shell, 需要明确可执行文件的路径
```

## 例子

elixir

```elixir
defmodule PortDemo do
  require Logger

  def start_link(python_path, script) do
    pid = spawn_link(__MODULE__, :init, [python_path, script])
    Process.register(pid, __MODULE__)
    {:ok, pid}
  end

  def send(data) when is_binary(data) do
    send(__MODULE__, {:send, data})
    :ok
  end

  def send_wait(data) when is_binary(data) do
    caller = self()
    ref = make_ref()
    send(__MODULE__, {:send_wait, data, caller, ref})

    receive do
      {^ref, response} -> response
    after
      5_000 -> {:error, :timeout}
    end
  end

  def stop do
    send(__MODULE__, :stop)
  end

  def init(python_path, script) do
    port =
      Port.open(
        {:spawn_executable, python_path},
        [
          :binary,
          :exit_status,
          {:packet, 2},
          args: ["-u", script]
        ]
      )

    loop(port, nil)
  end

  defp loop(port, caller) do
    receive do
      {:send, data} ->
        Port.command(port, data)
        loop(port, caller)

      {:send_wait, data, pid, ref} ->
        Port.command(port, data)
        loop(port, {pid, ref})

      {^port, {:data, data}} ->
        case Jason.decode(data) do
          {:ok, decoded} ->
            Logger.debug("elixir 收到 #{inspect(decoded)}")

            case caller do
              {pid, ref} ->
                send(pid, {ref, decoded})
                loop(port, nil)

              _ ->
                loop(port, caller)
            end

          {:error, _} ->
            loop(port, caller)
        end

      {^port, {:exit_status, status}} ->
        Logger.error("exited with status #{status}, restarting...")
        exit({:port_died, status})

      :stop ->
        Port.close(port)
        exit(:normal)
    end
  end
end
```

```elixir
defmodule PortSup do
  use Supervisor

  def start_link(python_path, script) do
    Supervisor.start_link(__MODULE__, {python_path, script}, name: __MODULE__)
  end

  @impl true
  def init({python_path, script}) do
    children = [
      %{
        id: PortDemo,
        start: {PortDemo, :start_link, [python_path, script]},
        restart: :transient
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

```elixir
defmodule Demo do
  require Logger

  def start do
    python_path = :code.priv_dir(:demo) |> Path.join("py_demo/.venv/bin/python3")
    script = :code.priv_dir(:demo) |> Path.join("py_demo/main.py")

    PortSup.start_link(python_path, script)
  end

  def cmd1 do
    PortDemo.send_wait("111")
  end

  def cmd2 do
    PortDemo.send_wait("222")
  end

  def stop do
    PortDemo.stop()
    Supervisor.stop(PortSup)
  end
end
```

python

```python
import sys
import threading
import time
import signal
import json
import struct


running = True


def handle_sigterm(signum, frame):
    global running
    running = False
    print("SIGTERM received, shutting down...", file=sys.stderr)


def write_frame(data):
    """写帧到 stdout（2 字节长度头 + JSON 体）→ Port → Elixir"""
    msg = json.dumps(data, ensure_ascii=False).encode("utf-8")
    header = struct.pack(">H", len(msg))
    sys.stdout.buffer.write(header + msg)
    sys.stdout.buffer.flush()


def read_frame():
    """从 stdin 读一帧（2 字节长度头 + 消息体）← Elixir"""
    header = sys.stdin.buffer.read(2)
    if not header or len(header) < 2:
        return None
    length = struct.unpack(">H", header)[0]
    body = sys.stdin.buffer.read(length)
    if not body or len(body) < length:
        return None
    return body.decode("utf-8")


def reading_loop():
    global running
    while running:
        data = read_frame()
        if data is None:
            print("stdin closed, exiting...", file=sys.stderr)
            running = False
            break
        print(f"py 收到: {data}", file=sys.stderr)
        write_frame({"type": "echo", "data": data})


def writing_loop():
    count = 0
    while running:
        time.sleep(30)
        if not running:
            break
        count += 1
        write_frame({"type": "heartbeat", "count": count})


def main():
    signal.signal(signal.SIGTERM, handle_sigterm)
    signal.signal(signal.SIGINT, handle_sigterm)

    print("started", file=sys.stderr)

    threading.Thread(target=reading_loop, daemon=True).start()
    threading.Thread(target=writing_loop, daemon=True).start()

    while running:
        time.sleep(1)


if __name__ == "__main__":
    main()
```
