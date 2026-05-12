# light_cdp

## 说明

结合浏览器做 html 解析，支持 js

## 例子

### 浏览器

chrome

```sh
chrome://inspect/#remote-debugging
```

或者

```sh
# 复制配置
# export DEFAULT_DATA_DIR=~/.config/google-chrome
export DEFAULT_DATA_DIR=~/.config/chromium
export DATA_DIR=/tmp/chrome_debug

rm -rf $DATA_DIR
mkdir -p $DATA_DIR

rsync -a --exclude='*Cache*' "$DEFAULT_DATA_DIR/" "$DATA_DIR"

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

    # window.onload
    :ok = LightCDP.Page.navigate(page, "https://www.baidu.com")
    {:ok, html} = LightCDP.Page.content(page)
    Logger.debug("百度首页 #{inspect(html)}")

    :ok = LightCDP.Page.fill(page, "#chat-textarea", "调试分析")

    # 等它出现
    :ok = LightCDP.Page.wait_for_selector(page, "#ci-submit-button", timeout: 5_000)
    LightCDP.Page.click(page, "#ci-submit-button")

    {:ok, html} = LightCDP.Page.content(page)
    Logger.debug("二级页面 #{inspect(html)}")

    LightCDP.stop(session)
  end
end
```

js 处理

```html
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <title>动态加载测试页面</title>
  </head>
  <body>
    <script>
      setTimeout(function () {
        var div = document.createElement("div");
        div.id = "aaa";
        div.textContent = "这是一个动态加载的 dom";
        document.body.appendChild(div);
        console.log("[页面] #aaa 已动态插入");
      }, 3000);
    </script>
  </body>
</html>
```

```elixir
defmodule Demo do
  require Logger

  def demo do
    {:ok, session} = LightCDP.start(host: "127.0.0.1", port: 9222)
    {:ok, page} = LightCDP.new_page(session)

    js = """
      function on_ready() {
        return new Promise((resolve) => {
          function check() {
            const dom = document.getElementById("aaa");
            if (dom) {
              alert("找到 dom");
              resolve(dom);
            } else {
              // 单位 ms
              setTimeout(check, 50);
            }
          }
          check();
        });
      }

      window.__on_ready = on_ready();
    """

    {:ok, _} =
      LightCDP.Connection.send_command(
        page.conn,
        "Page.addScriptToEvaluateOnNewDocument",
        %{source: js},
        5_000,
        page.session_id
      )

    :ok = LightCDP.Page.navigate(page, "http://127.0.0.1:8000/index.html")

    {:ok, title} = LightCDP.Page.evaluate(page, "document.title")
    Logger.debug("title #{inspect(title)}")

    LightCDP.stop(session)
  end
end
```
