# port

## 说明

用于和外部命令交互

- Port.open 调用的命令，应该是阻塞式的，否则 port 会直接退出
- 如果 Port.open 调用的命令被其他程序杀掉，port 收不到消息
- 调用 Port.close 以后，有些进程会被关闭，有些不能关闭的，需要另外杀掉
- Port.open 会把命令推到后台运行，System.cmd, System.shell 是直接在前台运行

## 用法

### 执行命令

```elixir
# port = Port.open({:spawn, "sleep 1000"}, [:binary])

file = System.find_executable("sleep")
port = Port.open({:spawn_executable, file}, [:binary, args: ["3600"]])

receive do
{^port, {:data, msg}} ->
  IO.inspect(msg)
end

# 系统进程的 pid 可以这么关掉
pid = Port.info(port)[:os_pid]
Port.close(port)
System.cmd("kill", ["-9",Integer.to_string(pid)])
```

类似

```elixir
"sleep" |> System.cmd(["10"])
```

### 互相通信

#### rust

```sh
cargo new rust_demo
cd rust_demo
cargo add erlang_port
```

代码

```rust
fn upper(mut s: String) -> Result<String, String> {
    s.make_ascii_uppercase();
    Ok(s)
}

fn main() {
   use erlang_port::{PortReceive, PortSend};

  let mut port = unsafe {
      use erlang_port::PacketSize;
      erlang_port::nouse_stdio(PacketSize::Four)
  };

  for string_in in port.receiver.iter() {
      let result = upper(string_in);

      port.sender.reply(result);
  }
}
```

编译

```sh
cargo build --release
```

#### elixir

port_gen_server.ex

```elixir
defmodule PortGenServer do
  use GenServer
  require Logger

  def start_link(port_bin_file_path) do
    {:ok, pid} = GenServer.start_link(__MODULE__, port_bin_file_path, name: __MODULE__)
    Logger.debug("gen_server pid is #{inspect(pid)}")
    {:ok, pid}
  end

  def init(port_bin_file_path) do
    port =
      Port.open({:spawn_executable, port_bin_file_path}, [
        {:packet, 4},
        :nouse_stdio,
        :binary,
        :exit_status
      ])

    {:ok, port}
  end

  def handle_call({:is_alive}, _from, state = port) do
    pid = Port.info(port)[:os_pid]

    is_alive =
      if pid == nil do
        false
      else
        Logger.debug("pid is #{pid}")
        true
      end

    {:reply, is_alive, state}
  end

  def handle_call({:do_demo, data}, _from, state = port) do
    Port.command(port, data)

    result =
      receive do
        {^port, {:data, bin_data}} ->
          {:ok, data} = :erlang.binary_to_term(bin_data)
          data
      end

    {:reply, result, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def terminate(reason, _state = port) do
    Port.close(port)
    IO.inspect("reason #{inspect(reason)} in terminate")
  end

  # -------------------------------------------------------------------------------------------------------

  def is_alive() do
    GenServer.call(__MODULE__, {:is_alive})
  end

  def do_demo(data) do
    GenServer.call(__MODULE__, {:do_demo, data})
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def async_stop do
    GenServer.cast(__MODULE__, :stop)
  end
end
```

port_sup.ex

```elixir
defmodule PortSup do
  use Supervisor

  def start_link(port_bin_file_path) do
    Supervisor.start_link(__MODULE__, [port_bin_file_path], name: __MODULE__)
  end

  def init([port_bin_file_path]) do
    children = [
      %{
        id: PortGenServer,
        start: {PortGenServer, :start_link, [port_bin_file_path]},
        restart: :transient
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

demo.ex

```elixir
defmodule Demo do
  @bin_file "/home/xxx/downloads/rust_demo/target/release/demo"
  def start_link do
    PortSup.start_link(@bin_file)
  end

  def is_bin_proc_alive() do
    PortGenServer.is_alive()
  end

  def do_demo() do
    PortGenServer.do_demo(:erlang.term_to_binary("hello"))
  end

  def close() do
    PortGenServer.stop()
    Supervisor.delete_child(PortSup, PortGenServer)
  end

  def debug do
    Supervisor.which_children(PortSup)
  end
end
```
