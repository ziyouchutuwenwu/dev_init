defmodule Demo2.ArticleListSpider do
  require Logger
  alias Demo2.{ArticleListSup, ArticleHtmlSup}

  def start_link(type_map, url, query_param_map, header_param_map) do
    Task.start_link(__MODULE__, :run, [
      type_map,
      url,
      query_param_map,
      header_param_map
    ])
  end

  def run(type_map, url, query_param_map, header_param_map) do
    Sleeper.random_deplay()
    start_request(type_map, url, query_param_map, header_param_map)
  end

  def start_request(type_map, url, query_param_map, header_param_map) do
    headers = [
      {"User-Agent", RandomUA.get_ua()},
      {"Referer", header_param_map["Referer"]},
      {"Content-Type", header_param_map["Content-Type"]},
      {"Host", header_param_map["Host"]}
    ]

    options = ConfigFetcher.get_httpoison_config()

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.post(url, {:form, query_param_map}, headers, options)

    parse_item(type_map, body, url, query_param_map, header_param_map)
  end

  def parse_item(type_map, body, url, query_param_map, header_param_map) do
    {:ok, doc} = body |> Floki.parse_document()

    nodes = doc |> Floki.find("record")

    Enum.each(nodes, fn node ->
      {_, _, [li_node]} = node
      href = li_node |> Floki.find("a") |> Floki.attribute("href") |> Floki.text()

      link =
        cond do
          href |> String.downcase() |> String.starts_with?("http://") === true ->
            href

          href |> String.downcase() |> String.starts_with?("https://") === true ->
            href

          true ->
            base_url = UrlHelper.get_base_url(url)
            URI.merge(URI.parse(base_url), href) |> to_string()
        end

      Logger.debug("文章页 #{link}")
      ArticleHtmlSup.start_child(type_map, link)
    end)

    current_record = url |> URI.decode_query() |> Map.get("endrecord") |> String.to_integer()
    total_records = doc |> Floki.find("totalrecord") |> Floki.text() |> String.to_integer()

    if current_record < total_records do
      base_url = url |> String.split("?") |> Enum.at(0)

      full_url =
        base_url
        |> URI.parse()
        |> URI.append_query("startrecord=#{current_record + 1}")
        |> URI.append_query("endrecord=#{current_record + 45}")
        |> URI.append_query("perpage=15")
        |> URI.to_string()

      Logger.debug("下一页 full_url #{full_url}")

      ArticleListSup.start_child(
        type_map,
        full_url,
        query_param_map,
        header_param_map
      )
    end
  end
end
