# hex 找不到

## 说明

debian 下，elixir-ls 会报错，提示 hex 找不到

## 解决方式

### 方法 1

先装好 hex

```sh
mix local.hex
```

然后

```sh
sudo ln -s ~/.mix/archives/hex-2.1.1/hex-2.1.1 /usr/lib/elixir/lib/hex --force
```

### 方法 2

installer.exs

添加方法

```elixir
defp load_hex do
  if !Code.ensure_loaded?(Hex) do
    base_dir = System.user_home |> Path.join(".mix/archives")

    if base_dir |> File.exists? do
      sub_dirs = File.ls!(base_dir)
      if sub_dirs |> Enum.count() > 0 do
        hex_dirs = Enum.filter(sub_dirs, fn dir -> dir |> String.starts_with?("hex-") end)

        hex_dir = Enum.reduce(hex_dirs, fn dir, saved_dir ->
          start_pos = String.length("hex-")
          ver1 = dir |> String.slice(start_pos..-1) |> Version.parse!()
          ver2 = saved_dir |> String.slice(start_pos..-1) |> Version.parse!()

          case Version.compare(ver1, ver2) do
            :gt ->
              dir
            :lt ->
              saved_dir
            :eq ->
              [dir, saved_dir] |> Enum.random()
          end
        end)

        hex_beam_path = base_dir |> Path.join(hex_dir) |> Path.join(hex_dir) |> Path.join("ebin")
        Code.append_path(hex_beam_path)
        # Code.prepend_path(hex_beam_path)
      end
    end
  end
end
```

line 342， cond 语句之前

```elixir
load_hex()
cond do xxx
```
