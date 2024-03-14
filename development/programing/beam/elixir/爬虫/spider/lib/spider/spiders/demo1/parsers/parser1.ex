defmodule Demo1.ArticleParser1 do
  def parse_item(doc) do
    case doc |> Floki.find(".tong_connr") do
      [] ->
        %{}

      _ ->
        title =
          doc
          |> Floki.find(".tong_con_title")
          |> Floki.text()
          |> String.trim("\n")
          |> String.trim()

        info_list = doc |> Floki.find(".tong_liulan") |> Floki.text() |> String.split()

        source_info =
          Enum.find(info_list, fn info ->
            String.contains?(info, "来源：")
          end)

        source = StrExt.sub_string_after_string(source_info, "来源：")

        update_time_info =
          Enum.find(info_list, fn info ->
            String.contains?(info, "更新时间：")
          end)

        update_time = StrExt.sub_string_after_string(update_time_info, "更新时间：")

        content_nodes = doc |> Floki.find(".tong_connr") |> Floki.find("p")

        content =
          List.foldl(content_nodes, "", fn content_node, saved_item ->
            strong_nodes = Floki.find(content_node, "strong")
            texts = Floki.text(content_node)

            # strong 只是修改样式
            strong_text =
              if length(strong_nodes) !== 0 do
                "<strong>" <> Floki.text(strong_nodes) <> "</strong>"
              end

            data_to_append =
              cond do
                strong_text === nil ->
                  "\n" <> texts

                String.length(texts) === 0 ->
                  "\n" <> strong_text

                true ->
                  "\n" <> strong_text <> "\n" <> texts
              end

            saved_item <> data_to_append
          end)

        content = String.trim(content)

        %{
          "title" => title,
          "update_time" => update_time,
          "source" => source,
          "content" => content
        }
    end
  end
end
