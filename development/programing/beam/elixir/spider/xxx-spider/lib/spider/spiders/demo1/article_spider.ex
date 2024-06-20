defmodule Demo1.ArticleSpider do
  require Logger
  alias Hasher.UrlHasher
  alias Demo1.{ArticleParser1}

  def start_link(type_map, url) do
    Task.start_link(__MODULE__, :run, [type_map, url])
  end

  def run(type_map, url) do
    Sleeper.random_deplay()
    start_request(type_map, url)
  end

  def start_request(type_map, url) do
    headers = [{"User-Agent", RandomUA.get_ua()}]

    options = ConfigFetcher.get_httpoison_config()
    response = HTTPoison.get!(url, headers, options)

    case response.status_code do
      200 ->
        resp_body = response.body
        resp_encoding = response.headers |> Map.new() |> Map.get("Content-Encoding")

        body =
          case resp_encoding do
            "gzip" ->
              :zlib.gunzip(resp_body)

            _ ->
              resp_body
          end

        parse_item(type_map, url, body)

      _ ->
        Logger.debug("返回 #{response.status_code} url #{url}")
    end
  end

  def parse_item(type_map, url, body) do
    {:ok, doc} = Floki.parse_document(body)

    entity1 = ArticleParser1.parse_item(doc)

    entity_map =
      cond do
        entity1 |> map_size() > 0 ->
          entity1

        true ->
          throw("文章解析 #{url} 失败")
      end

    %{
      "title" => title,
      "content" => content
    } = entity_map

    if String.length(title) !== 0 && String.length(content) !== 0 do
      item =
        entity_map
        |> Map.merge(%{
          "save_time" => TimeExt.get_now_time(),
          "url" => url
        })

      if UrlHasher.is_url_hash_need_update(url, content) do
        base_path = ConfigFetcher.get_data_save_base_dir()
        filepath = Path.join(base_path, TimeExt.get_today())

        filepath = PathHelper.check_path_join(filepath, type_map, "main_type_name")
        filepath = PathHelper.check_path_join(filepath, type_map, "sub1_type_name")
        filepath = PathHelper.check_path_join(filepath, type_map, "sub2_type_name")
        filepath = PathHelper.check_path_join(filepath, type_map, "sub3_type_name")
        filepath = PathHelper.check_path_join(filepath, type_map, "sub4_type_name")
        filepath = PathHelper.check_path_join(filepath, type_map, "sub5_type_name")

        File.mkdir_p(filepath)
        filename = title <> ".txt"
        file = Path.join(filepath, filename)

        # 写文件失败抛异常
        File.write!(file, Jason.encode!(item), [:binary])

        UrlHasher.set_url_hash(url, content)
      end
    end
  end
end
