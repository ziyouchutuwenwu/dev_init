# atomvm

## 说明

基于 beam 的单片机开发

一些模块不支持

```elixir
Application
Logger
```

## 步骤

### 环境

rtos + 外设驱动 + 虚拟机引擎 + 核心标准库

只要烧录一次

```sh
curl -fLO https://github.com/atomvm/AtomVM/releases/download/v0.7.0-beta.0/AtomVM-esp32s3-elixir-v0.7.0-beta.0.img
```

```sh
# 擦除并刷入底层固件
esptool.py --chip esp32s3 --port /dev/ttyACM0 erase_flash
esptool.py --chip esp32s3 --port /dev/ttyACM0 write_flash 0x0 AtomVM-esp32s3-elixir-v0.7.0-beta.0.img
```

### 项目

```sh
mix new demo
```

mix.exs

```elixir
defmodule MyBlink.MixProject do
  use Mix.Project

  def project do
    [
      ......
      deps: deps(),
      atomvm: [
        # 必须指定模块
        start: Demo
      ]
    ]
  end

  defp deps do
    [
      {:atomvm, "~> 0.7.0-beta.0", runtime: false},
      {:exatomvm, git: "https://github.com/atomvm/exatomvm.git", runtime: false}
    ]
  end
end
```

### 代码

```elixir
defmodule Demo do
  @compile {:no_warn_undefined, [:esp]}

  def start do
    Logger.info("demo starting under supervisor on atomvm")

    Process.flag(:trap_exit, true)
    {:ok, sup} = Demo.Supervisor.start_link([])

    receive do
      {:EXIT, ^sup, reason} ->
        Logger.error("supervisor crashed: #{inspect(reason)}, rebooting esp32...")
        :timer.sleep(1000)
        :esp.restart()
    end
  end
end
```

```elixir
defmodule Demo.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      Demo.BlinkWorker,
      Demo.WifiWorker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

```elixir
defmodule Demo.BlinkWorker do
  use GenServer
  @compile {:no_warn_undefined, [:gpio]}

  @led_pin 2

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    :gpio.set_pin_mode(@led_pin, :output)
    :timer.send_after(500, :toggle)
    Logger.info("blink worker started on pin #{@led_pin}")
    {:ok, 0}
  end

  @impl true
  def handle_info(:toggle, level) do
    next =
      if level == 1 do
        0
      else
        1
      end

    :gpio.digital_write(@led_pin, next)
    :timer.send_after(500, :toggle)
    {:noreply, next}
  end

  @impl true
  def handle_call(_msg, _from, state), do: {:reply, :ok, state}

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}
end
```

```elixir
defmodule Demo.WifiWorker do
  use GenServer
  @compile {:no_warn_undefined, [:network]}

  @wifi_ssid "xxxxxxxx"
  @wifi_pwd "123456"

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    send(self(), :connect_wifi)
    {:ok, %{status: :disconnected}}
  end

  @impl true
  def handle_info(:connect_wifi, state) do
    Logger.info("connecting to wifi '#{@wifi_ssid}'...")

    case :network.wait_for_sta([ssid: @wifi_ssid, psk: @wifi_pwd], 30000) do
      {:ok, ip_info} ->
        Logger.info("wifi connected successfully, ip info: #{inspect(ip_info)}")
        {:noreply, %{state | status: :connected}}

      {:error, reason} ->
        Logger.error("failed to connect to wifi: #{inspect(reason)}, retry in 5s...")
        :timer.send_after(5000, :connect_wifi)
        {:noreply, %{state | status: :error}}
    end
  end

  @impl true
  def handle_call(_msg, _from, state), do: {:reply, :ok, state}

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}
end
```

```elixir
defmodule Logger do
  def info(msg, _meta \\ []), do: IO.puts("[info] #{format_msg(msg)}")
  def warning(msg, _meta \\ []), do: IO.puts("[warning] #{format_msg(msg)}")
  def warn(msg, _meta \\ []), do: IO.puts("[warning] #{format_msg(msg)}")
  def error(msg, _meta \\ []), do: IO.puts("[error] #{format_msg(msg)}")
  def debug(msg, _meta \\ []), do: IO.puts("[debug] #{format_msg(msg)}")
  def notice(msg, _meta \\ []), do: IO.puts("[notice] #{format_msg(msg)}")
  def critical(msg, _meta \\ []), do: IO.puts("[critical] #{format_msg(msg)}")
  def alert(msg, _meta \\ []), do: IO.puts("[alert] #{format_msg(msg)}")
  def emergency(msg, _meta \\ []), do: IO.puts("[emergency] #{format_msg(msg)}")

  def flush, do: :ok

  defp format_msg(fun) when is_function(fun, 0), do: fun.()
  defp format_msg(msg), do: msg
end
```

### 烧录

```sh
# 编译打包
mix atomvm.packbeam

# 烧录
mix atomvm.esp32.flash --port /dev/ttyACM0
```
