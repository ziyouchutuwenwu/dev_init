defmodule PathHelper do
  # 用以支持 type_map 里面的动态路径
  def check_path_join(prev_path, type_map, key) do
    value = Map.get(type_map, key)

    if value !== nil do
      Path.join(prev_path, value)
    else
      prev_path
    end
  end
end
