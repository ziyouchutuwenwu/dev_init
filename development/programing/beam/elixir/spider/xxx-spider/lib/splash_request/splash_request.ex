defmodule SplashRequest do
  # {:ok, %HTTPoison.Response{status_code: 200, body: body}} = SplashRequest.do_get("http://127.0.0.1:8050", url)
  def do_get(splash_url, dest_url) do
    body_json =
      Jason.encode!(%{
        url: dest_url,
        resource_timeout: 20,
        viewport: "1024x768",
        render_all: false,
        images: 0,
        http_method: "GET",
        html5_media: false,
        http2: true,
        load_args: Map.new(),
        wait: 15,
        timeout: 3600,
        request_body: false,
        response_body: false,
        engine: "webkit",
        har: 0,
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
    request_url = splash_url |> URI.parse |> URI.merge("execute") |> to_string()

    {:ok, %HTTPoison.Response{status_code: 200, body: json_response}} = HTTPoison.post(request_url, body_json, headers, options)

    response_map = Jason.decode!(json_response)

    {:ok, %HTTPoison.Response{status_code: 200, body: response_map["html"]}}
  end
end
