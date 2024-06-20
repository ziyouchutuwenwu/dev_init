defmodule Demo1.ArticleListSpider do
  require Logger

  def start_link(sup_name_map, type_map, url) do
    Task.start_link(__MODULE__, :run, [sup_name_map, type_map, url])
  end

  def run(sup_name_map, type_map, url) do
    Sleeper.random_deplay()
    start_request(sup_name_map, type_map, url)
  end

  def start_request(sup_name_map, type_map, url) do
    # splash_url = ConfigFetcher.get_splash_url()
    # {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
    #   SplashRequest.do_get(splash_url, url)

    headers = [{"User-Agent", RandomUA.get_ua()}]

    options = ConfigFetcher.get_httpoison_config()
    response = HTTPoison.get!(url, headers, options)

    case response.status_code do
      200 ->
        body = response.body
        parse_item(sup_name_map, type_map, body, url)

      301 ->
        resp_headers = response.headers |> Map.new()
        redirected_url = resp_headers |> Map.get("Location")

        {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
          HTTPoison.get(redirected_url, headers, options)

        parse_item(sup_name_map, type_map, body, url)
    end
  end

  def parse_item(sup_name_map, type_map, body, request_url) do
    article_list_sup = sup_name_map["article_list_sup"]
    article_sup = sup_name_map["article_sup"]

    {:ok, doc} = Floki.parse_document(body)

    nodes = Floki.find(doc, ".tong_list a")

    Enum.each(nodes, fn node ->
      href = node |> Floki.attribute("href") |> Floki.text()

      link =
        cond do
          href |> String.downcase() |> String.starts_with?("http://") === true ->
            href

          href |> String.downcase() |> String.starts_with?("https://") === true ->
            href

          true ->
            base_url = UrlHelper.get_url_without_last_part(request_url)
            UrlHelper.join(base_url, href)
        end

      article_sup.start_child(type_map, link)
    end)

    page_nodes = doc |> Floki.find(".page_fy a")

    Enum.each(page_nodes, fn page_node ->
      node_text = String.trim(Floki.text(page_node))
      next_page_url = page_node |> Floki.attribute("href") |> Floki.text()

      if node_text |> String.equivalent?("下一页") do
        article_list_sup.start_child(type_map, next_page_url)
      end
    end)
  end
end
