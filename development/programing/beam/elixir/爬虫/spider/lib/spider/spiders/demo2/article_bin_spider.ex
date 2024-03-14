defmodule Demo2.ArticleBinSpider do
  require Logger
  alias Demo2.{ArticleTikaSup}

  def start_link(type_map, entity_extra_info_map, url) do
    Task.start_link(__MODULE__, :run, [type_map, entity_extra_info_map, url])
  end

  def run(type_map, entity_extra_info_map, url) do
    Sleeper.random_deplay()
    start_request(type_map, entity_extra_info_map, url)
  end

  def start_request(type_map, entity_extra_info_map, url) do
    headers = [{"User-Agent", RandomUA.get_ua()}]

    options = ConfigFetcher.get_httpoison_config()

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.get(url, headers, options)
    ArticleTikaSup.start_child(type_map, entity_extra_info_map, body)
  end
end
