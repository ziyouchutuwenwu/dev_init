# splash

## 步骤

| 字段        | 说明                                                                           |
| ----------- | ------------------------------------------------------------------------------ |
| maxrss      | splash 每分钟检测内存，如果超过 xxx, 则重启                                    |
| memory      | docker 的内存限制，备用                                                        |
| slots       | splash 并发数，如果所有 slots 都满了，请求会排队，在内部排队的时候，就开始计数 |
| max-timeout | 默认最大只能 90 秒，修改此参数增加超时时间                                     |

### 启动

```sh
docker run --rm -d --name splash-dev \
  --add-host=maxcdn.bootstrapcdn.com:127.0.0.1 \
  --add-host=cdnjs.cloudflare.com:127.0.0.1 \
  --dns=223.5.5.5 -p 8050:8050 \
  --memory 4.5G scrapinghub/splash \
  --maxrss 4000 --slots 20 --max-timeout 3600
```

### 代码

```elixir
{:ok, %HTTPoison.Response{status_code: 200, body: body}} = SplashRequest.do_get("http://127.0.0.1:8050", url)
```

```elixir
defmodule SplashRequest do
  def do_get(splash_url, dest_url) do
    body_json =
      Jason.encode!(%{
        url: dest_url,
        resource_timeout: 20,
        viewport: "1024x768",
        render_all: false,
        images: 1,
        http_method: "GET",
        html5_media: false,
        http2: true,
        load_args: Map.new(),
        wait: 15,
        timeout: 3600,
        request_body: false,
        response_body: false,
        engine: "webkit",
        har: 1,
        png: 0,
        html: 1,
        lua_source:
          "function main(splash, args)\r\n  splash:go(args.url)\r\n  return {\r\n    html = splash:html()\r\n  }\r\nend"
      })

    headers = [
      {"Content-type", "application/json"},
      {"User-Agent", RandomUA.get_ua()}
    ]

    options = ConfigFetcher.get_httpoison_config()
    request_url = splash_url |> URI.parse() |> URI.merge("execute") |> to_string()

    {:ok, %HTTPoison.Response{status_code: 200, body: json_response}} =
      HTTPoison.post(request_url, body_json, headers, options)

    response_map = Jason.decode!(json_response)

    {:ok, %HTTPoison.Response{status_code: 200, body: response_map["html"]}}
  end
end
```
