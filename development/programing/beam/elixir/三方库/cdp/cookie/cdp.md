# cdp

## 说明

cookie 的例子

## 代码

```elixir
defmodule Demo do
  require Logger

  def demo1 do
    {:ok, session} = LightCDP.start(host: "127.0.0.1", port: 9222)
    {:ok, page} = LightCDP.new_page(session)
    conn = page.conn
    session_id = page.session_id

    url = "http://127.0.0.1:8000/login.html"
    uri = URI.parse(url)

    :ok = LightCDP.Page.navigate(page, url)
    Logger.debug("已打开登录页")

    LightCDP.Page.fill(page, "#username", "admin")
    LightCDP.Page.fill(page, "#password", "123456")

    # 等待闭包执行结束，等待当前页跳转
    LightCDP.Page.wait_for_navigation(page, fn ->
      LightCDP.Page.click(page, "#login-btn")
    end)

    {:ok, %{"cookies" => all_cookies}} =
      LightCDP.Connection.send_command(conn, "Network.getAllCookies", %{}, 5_000, session_id)

    site_cookies =
      Enum.filter(all_cookies, fn cookie ->
        cookie["domain"] == uri.host && cookie["sourcePort"] == uri.port
      end)

    File.write!("cookies.jsonc", Jason.encode!(site_cookies))
    Logger.debug("已保存 #{length(site_cookies)} 个 cookie 到 cookies.json")

    {:ok, status} = LightCDP.Page.evaluate(page, "document.getElementById('status').innerText")
    Logger.debug("登录状态: #{status}")

    LightCDP.stop(session)
  end

  def demo2 do
    {:ok, session} = LightCDP.start(host: "127.0.0.1", port: 9222)
    {:ok, page} = LightCDP.new_page(session)
    conn = page.conn
    session_id = page.session_id

    url = "http://127.0.0.1:8000/dashboard.html"
    uri = URI.parse(url)
    base_url = "#{uri.scheme}://#{uri.host}:#{uri.port}"

    cookies =
      "cookies.jsonc"
      |> File.read!()
      |> Jason.decode!()

    for cookie <- cookies do

      # 筛选字段
      filtered_cookie =
        Map.take(cookie, [
          "name",
          "value",
          "domain",
          "path",
          "secure",
          "httpOnly",
          "sameSite",
          "expires"
        ])

      LightCDP.Connection.send_command(
        conn,
        "Network.setCookie",
        Map.put(filtered_cookie, "url", base_url),
        5_000,
        session_id
      )
    end

    Logger.debug("已从 cookies.json 加载 #{length(cookies)} 个 cookie")

    :ok = LightCDP.Page.navigate(page, url)

    {:ok, status} = LightCDP.Page.evaluate(page, "document.getElementById('status').innerText")
    Logger.debug("登录状态: #{status}")

    LightCDP.stop(session)
  end
end
```
