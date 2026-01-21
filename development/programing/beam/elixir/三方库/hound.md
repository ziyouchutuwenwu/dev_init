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
  browser: "chrome_headless",
  # chromedriver 默认端口
  port: 9515
```

```elixir
defmodule Demo do
  use Hound.Helpers

  def demo do
    Hound.start_session([additional_capabilities: %{browserName: "chrome"}])
    navigate_to("https://www.baidu.com")
    Hound.end_session()
  end
end
```
