# light_cdp

## 说明

结合浏览器做 html 解析，支持 js

## 例子

### 浏览器

chrome

```sh
# 复制配置
# export DEFAULT_DATA_DIR=~/.config/google-chrome
export DEFAULT_DATA_DIR=~/.config/chromium
export DATA_DIR=/tmp/chrome_debug

rm -rf $DATA_DIR
mkdir -p $DATA_DIR

rsync -av --exclude='*Cache*' "$DEFAULT_DATA_DIR/" "$DATA_DIR"

chromium \
  --user-data-dir=$DATA_DIR \
  --remote-debugging-address=0.0.0.0 \
  --remote-debugging-port=9222
```

zig 版 [lightpanda](https://github.com/lightpanda-io/browser)

```sh
lightpanda serve --host 127.0.0.1 --port 9222 --user-agent xxx-user
```

rust 版 [obscura](https://github.com/h4ckf0r0day/obscura)

```sh
obscura serve --stealth --port 9222 --user-agent xxx-user
```

依赖

```elixir
defp deps do
  [
    {:light_cdp, github: "lessless/light_cdp"}
  ]
end
```

### 代码

```elixir
defmodule Demo do
  require Logger

  def demo do
    {:ok, session} = LightCDP.start(host: "127.0.0.1", port: 9222)
    {:ok, page} = LightCDP.new_page(session)

    # https://httpbin.org/ip
    :ok = LightCDP.Page.navigate(page, "https://httpbin.org/user-agent")
    {:ok, html} = LightCDP.Page.content(page)
    Logger.debug(inspect(html))

    LightCDP.stop(session)
  end
end
```
