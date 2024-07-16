defmodule Demo2.ArticleTikaSpider do
  require Logger
  alias Hasher.UrlHasher

  def start_link(type_map, entity_extra_info_map, file_bin) do
    Task.start_link(__MODULE__, :run, [type_map, entity_extra_info_map, file_bin])
  end

  def run(type_map, entity_extra_info_map, file_bin) do
    Sleeper.random_deplay()
    start_request(type_map, entity_extra_info_map, file_bin)
  end

  def start_request(type_map, entity_extra_info_map, file_bin) do
    tika_url = ConfigFetcher.get_tika_url()

    headers = [{"User-Agent", RandomUA.get_ua()}]

    options = ConfigFetcher.get_httpoison_config()

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.put(tika_url, file_bin, headers, options)

    parse_item(type_map, entity_extra_info_map, body)
  end

  def parse_item(type_map, entity_extra_info_map, body) do
    {:ok, doc} = body |> Floki.parse_document()
    pnodes = doc |> Floki.find("body p")

    content =
      List.foldl(pnodes, "", fn pnode, saved_text ->
        text = pnode |> Floki.text() |> String.trim()

        case text do
          "" ->
            saved_text

          _ ->
            saved_text <> text <> "\n"
        end
      end)

    content = content |> String.trim("\n")

    title = entity_extra_info_map["title"]
    url = entity_extra_info_map["url"]

    if String.length(title) !== 0 && String.length(content) !== 0 do
      item =
        entity_extra_info_map
        |> Map.merge(%{
          "save_time" => TimeExt.get_now_time(),
          "content" => content
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
