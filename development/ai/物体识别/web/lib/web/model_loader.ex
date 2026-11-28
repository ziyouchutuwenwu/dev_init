defmodule Web.ModelLoader do
  require Logger
  @translations_file "translations.json"

  def load_model_label_info(gateway_url \\ nil) do
    case :persistent_term.get({__MODULE__, :cached_models}, nil) do
      cached_models when is_list(cached_models) and cached_models != [] ->
        cached_models

      _ ->
        load_available_models(gateway_url)
    end
  end

  def load_available_models(gateway_url \\ nil) do
    resolved_url = resolve_gateway_url(gateway_url)
    remote_items = fetch_remote_models(resolved_url)

    models =
      if remote_items != [] do
        translations = load_translations(@translations_file)

        Enum.map(remote_items, fn item ->
          model_item_to_map(item, translations)
        end)
      else
        case :persistent_term.get({__MODULE__, :cached_models}, nil) do
          cached_models when is_list(cached_models) and cached_models != [] ->
            cached_models

          _ ->
            []
        end
      end

    if models != [] do
      :persistent_term.put({__MODULE__, :cached_models}, models)
    end

    models
  end

  def resolve_gateway_url(gateway_url \\ nil) do
    url_candidate = to_string(gateway_url || "") |> String.trim()

    cond do
      url_candidate != "" ->
        url_candidate

      true ->
        db_url =
          try do
            Web.Orm.Query.Settings.get_gateway_url()
          rescue
            _ -> nil
          end

        clean_db_url = to_string(db_url || "") |> String.trim()

        cond do
          clean_db_url != "" ->
            clean_db_url

          true ->
            env_url = System.get_env("GATEWAY_URL") |> to_string() |> String.trim()

            if env_url != "" do
              env_url
            else
              "http://192.168.88.100:8181"
            end
        end
    end
  end

  defp fetch_remote_models(gateway_url) do
    clean_url = to_string(gateway_url || "") |> String.trim()

    if clean_url == "" do
      []
    else
      target_url = String.trim_trailing(clean_url, "/") <> "/api/models"

      try do
        case Req.get(target_url, connect_options: [timeout: 1000], receive_timeout: 2000, retry: false) do
          {:ok, %Req.Response{status: 200, body: %{"models" => models}}} when is_list(models) ->
            models

          {:ok, %Req.Response{status: 200, body: %{"groups" => groups}}} when is_list(groups) ->
            groups

          {:ok, %Req.Response{status: 200, body: models}} when is_list(models) ->
            models

          {:ok, %Req.Response{status: 200, body: body_str}} when is_binary(body_str) ->
            case Jason.decode(body_str) do
              {:ok, %{"models" => models}} when is_list(models) -> models
              {:ok, %{"groups" => groups}} when is_list(groups) -> groups
              {:ok, models} when is_list(models) -> models
              _ -> []
            end

          {:ok, %Req.Response{status: status, body: body}} ->
            Logger.warning("[model_loader] Rust server #{target_url} returned HTTP #{status}: #{inspect(body)}")
            []

          {:error, exception} ->
            Logger.warning("[model_loader] failed to request models from #{target_url}: #{Exception.message(exception)}")
            []
        end
      rescue
        exception ->
          Logger.warning("[model_loader] exception requesting models from #{target_url}: #{Exception.message(exception)}")
          []
      end
    end
  end

  def first_model_id do
    case load_model_label_info() do
      [%{id: first_id} | _] -> first_id
      _ -> ""
    end
  end

  def load_models_with_translations(translations) do
    Enum.map(load_model_label_info(), fn model ->
      classes =
        for class_item <- model.classes do
          code =
            class_item.code || class_item[:code] || class_item["code"] ||
              class_item.id || class_item[:id] || class_item["id"]

          %{class_item | name: translate(code, translations)}
        end

      %{model | classes: classes}
    end)
  end

  def get_model(model_id) do
    id_str = to_string(model_id || "")

    if id_str == "" do
      nil
    else
      case Enum.find(load_model_label_info(), &(&1.id == id_str)) do
        nil ->
          %{
            id: id_str,
            name: id_str,
            desc: id_str,
            classes: []
          }

        found_model ->
          found_model
      end
    end
  end

  def model_name(nil), do: "全部"
  def model_name(""), do: "全部"

  def model_name(model_id) do
    case get_model(model_id) do
      %{name: name} when is_binary(name) and name != "" -> name
      _ -> "全部"
    end
  end

  @spec classes_for_model(any()) :: list()
  def classes_for_model(nil), do: []
  def classes_for_model(""), do: []

  def classes_for_model(model_id) do
    case get_model(to_string(model_id)) do
      %{classes: classes} -> classes
      _ -> []
    end
  end

  def default_classes_for_model(model_id) do
    Enum.map(classes_for_model(model_id), & &1.id)
  end

  @spec translate(any(), nil | maybe_improper_list() | map()) :: any()
  def translate(class_id, translations) do
    id = to_string(class_id || "")
    lower = String.downcase(id)

    translations[id] ||
      translations[lower] ||
      translations[String.replace(lower, "_", "-")] ||
      translations[String.replace(lower, "-", "_")] ||
      translations[String.replace(lower, "_", " ")] ||
      translate_prefix(lower, translations) ||
      id
  end

  def load_translations(file) do
    with {:ok, content} <- File.read(Application.app_dir(:web, Path.join("priv", file))),
         {:ok, map} when is_map(map) <- Jason.decode(content) do
      map
    else
      _ -> %{}
    end
  end

  def label_display_map do
    translations = load_translations(@translations_file)

    Enum.reduce(load_models_with_translations(translations), translations, fn model, acc ->
      Enum.reduce(model.classes, acc, fn class_item, inner_acc ->
        name = class_item.name
        code = to_string(class_item.code)
        lower = String.downcase(code)

        inner_acc
        |> Map.put(code, name)
        |> Map.put(lower, name)
        |> Map.put(String.replace(lower, "_", "-"), name)
        |> Map.put(String.replace(lower, "-", "_"), name)
        |> Map.put(String.replace(lower, "_", " "), name)
        |> Map.put(String.replace(lower, " ", "_"), name)
        |> Map.put(String.replace(lower, " ", "-"), name)
      end)
    end)
  end

  defp translate_prefix("no-" <> rest, translations), do: "未" <> translate(rest, translations)
  defp translate_prefix("no_" <> rest, translations), do: "未" <> translate(rest, translations)
  defp translate_prefix(_, _), do: nil

  defp model_item_to_map(item, translations) do
    raw_id = item["id"] || item[:id] || ""
    raw_name = item["name"] || item[:name] || raw_id
    raw_desc = item["desc"] || item[:desc] || raw_name
    raw_classes = item["classes"] || item[:classes] || []

    id = to_string(raw_id || "")
    name = if is_binary(raw_name) and raw_name != "", do: raw_name, else: id
    desc = if is_binary(raw_desc) and raw_desc != "", do: raw_desc, else: name

    classes =
      if is_list(raw_classes) do
        for class_item <- raw_classes do
          class_str = to_string(class_item)

          %{
            id: class_str,
            code: class_str,
            name: translate(class_str, translations),
            tag: "检测项"
          }
        end
      else
        []
      end

    %{
      id: id,
      name: name,
      desc: desc,
      classes: classes
    }
  end
end
