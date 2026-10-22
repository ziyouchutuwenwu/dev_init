defmodule Web.ModelLoader do
  @translations_file "translations.json"

  def load_model_label_info do
    load_models_with_translations(load_translations(@translations_file))
  end

  def load_models_with_translations(translations) do
    for path <- Path.wildcard(Application.app_dir(:web, "priv/models/*.json")) |> Enum.sort(),
        {:ok, content} <- [File.read(path)],
        {:ok, model} <- [Jason.decode(content, keys: :atoms)] do
      model_info_to_map(model, translations)
    end
  end

  def get_model(model_id) do
    Enum.find(load_model_label_info(), &(&1.id == to_string(model_id)))
  end

  @spec classes_for_model(any()) :: any()
  def classes_for_model(model_id) do
    case get_model(model_id) do
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
      Enum.reduce(model.classes, acc, fn c, inner_acc ->
        name = c.name
        code = to_string(c.code)
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

  defp translate_prefix("no-" <> rest, t), do: "未" <> translate(rest, t)
  defp translate_prefix("no_" <> rest, t), do: "未" <> translate(rest, t)
  defp translate_prefix(_, _), do: nil

  defp model_info_to_map(model, translations) do
    classes =
      for c <- model[:classes] || [] do
        %{id: c, code: c, name: translate(c, translations), tag: "检测项"}
      end

    %{
      id: to_string(model[:id]),
      name: to_string(model[:name]),
      desc: to_string(model[:desc]),
      classes: classes
    }
  end
end
