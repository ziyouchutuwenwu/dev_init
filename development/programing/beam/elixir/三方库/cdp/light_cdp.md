# light_cdp

## 说明

浏览器自动化

## 配置

### 浏览器

```sh
chrome://inspect/#remote-debugging
```

chromium

```sh
chromium --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222
```

chrome

```sh
export DEFAULT_DATA_DIR=~/.config/google-chrome
export DATA_DIR=/tmp/chrome_debug

rm -rf $DATA_DIR
mkdir -p $DATA_DIR

rsync -a --exclude='*Cache*' "$DEFAULT_DATA_DIR/" "$DATA_DIR"

google-chrome-stable \
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
    # session 是 cdp 的实例，多个页面用同一个 session
    {:ok, session} = LightCDP.start(host: "127.0.0.1", port: 9222)
    {:ok, page} = LightCDP.new_page(session)

    # window.onload
    :ok = LightCDP.Page.navigate(page, "https://www.baidu.com")
    {:ok, html} = LightCDP.Page.content(page)
    Logger.debug("百度首页 #{inspect(html)}")

    :ok = LightCDP.Page.fill(page, "#chat-textarea", "调试分析")

    # 等它出现
    :ok = LightCDP.Page.wait_for_selector(page, "#ci-submit-button", timeout: 5_000)

    # 等待闭包执行结束，等待页面跳转，一定是当前页
    LightCDP.Page.wait_for_navigation(page, fn ->
      LightCDP.Page.click(page, "#ci-submit-button")
    end)
    # LightCDP.Page.click(page, "#ci-submit-button")

    {:ok, html} = LightCDP.Page.content(page)
    Logger.debug("二级页面 #{inspect(html)}")

    LightCDP.stop(session)
  end
end
```
