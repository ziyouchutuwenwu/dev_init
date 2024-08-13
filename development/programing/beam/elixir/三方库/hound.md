# hound

## 说明

使用 chrome 的自动化操作库

## 用法

### 准备

安装 chromedriver

```sh
yay -S chromedriver
#手动启动
chromedriver
```

### 代码

依赖

```elixir
{:hound, "~> 1.1.1"}
```

config/config.exs

```elixir
import Config

config :hound,
  driver: "chrome_driver",
  # chromedriver 默认端口
  port: 9515
```

```elixir
defmodule Demo do
  use Hound.Helpers

  def demo do
    Hound.start_session(additional_capabilities())
    navigate_to("https://www.baidu.com")
    Hound.end_session()
  end

  defp additional_capabilities do
    [
      additional_capabilities: %{
        :"goog:chromeOptions" => %{
          "args" => [
            "--headless",
            "--disable-gpu",
            "--no-sandbox",
            "--disable-dev-shm-usage",
            "--disable-software-rasterizer"
          ]
        }
      }
    ]
  end
end
```
