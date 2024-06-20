defmodule Demo2.ArticleHtmlSpider do
  require Logger
  alias Demo2.{ArticleBinSup}

  def start_link(type_map, url) do
    Task.start_link(__MODULE__, :run, [type_map, url])
  end

  def run(type_map, url) do
    Sleeper.random_deplay()
    start_request(type_map, url)
  end

  def start_request(type_map, url) do
    uri = url |> URI.parse()

    headers = [
      {"User-Agent", RandomUA.get_ua()},
      {"Accept",
       "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"},
      {"Accept-Encoding", "gzip, deflate, br"},
      {"Host", uri.host}
    ]

    options = ConfigFetcher.get_httpoison_config()

    {:ok, %HTTPoison.Response{status_code: 200, headers: resp_header, body: resp_body}} =
      HTTPoison.get(url, headers, options)

    resp_encoding = resp_header |> Map.new() |> Map.get("Content-Encoding")

    body =
      case resp_encoding do
        "gzip" ->
          :zlib.gunzip(resp_body)

        _ ->
          resp_body
      end

    parse_item(type_map, url, body)
  end

  def parse_item(type_map, url, body) do
    {:ok, doc} = Floki.parse_document(body)

    title =
      doc
      |> Floki.find(".con-title")
      |> Floki.text()
      |> String.trim()

    publish_date =
      doc
      |> Floki.find(".date")
      |> Floki.text()
      |> StrExt.sub_string_after_string("发布日期：")
      |> String.trim()

    nodes = doc |> Floki.find(".main-txt a")

    Enum.each(nodes, fn node ->
      href = node |> Floki.attribute("href") |> Floki.text()

      link =
        cond do
          href |> String.downcase() |> String.starts_with?("http://") === true ->
            href

          href |> String.downcase() |> String.starts_with?("https://") === true ->
            href

          true ->
            base_url = UrlHelper.get_base_url(url)
            UrlHelper.join(base_url, href)
        end

      Logger.debug("publish_date #{publish_date} pdf #{link}")

      entity_extra_info_map = %{
        "title" => title,
        "source" => "xxxxxx",
        "url" => url,
        "publish_date" => publish_date
      }

      ArticleBinSup.start_child(type_map, entity_extra_info_map, link)
    end)
  end
end
