# rustler

## 说明

[地址](https://github.com/rusterlium/rustler)

交叉编译用 zigbuild

## 步骤

### 准备

创建项目

```sh
mix new demo
```

mix.exs

```elixir
{:rustler, "~> 0.38.0", runtime: false}
```

```sh
mix deps.get
```

rust

```sh
mix rustler.new --module MyLib --name my_lib --opt-app demo
```

### 代码

demo_struct.ex

```elixir
defmodule DemoStruct do
  defstruct [:name, :age]

  def new(name, age) do
    %__MODULE__{name: name, age: age}
  end
end
```

demo.ex

```elixir
defmodule Demo do
  def elixir_demo do
    obj1 = DemoStruct.new("aaa", 111)
    obj2 = DemoStruct.new("bbb", 222)
    [obj1, obj2]
  end

  def list_demo1 do
    list = [10, 20, 30, 40]
    MyLib.list_demo1(list)
  end

  def list_demo2 do
    list = elixir_demo()
    MyLib.list_demo2(list)
  end

  def tuple_demo do
    tuple = {:aaa, :bbb}
    MyLib.tuple_demo(tuple)
  end
end
```

my_lib.ex

```elixir
defmodule MyLib do
  require Logger

  use Rustler,
    otp_app: :demo,
    crate: "my_lib",
    # 默认
    # mode: :release,
    # 默认位置，不需要修改，rustler 里面的宏定义
    # load_from: {:demo, "priv/native/my_lib"}

    # 用 zigbuild 来代替编译
    skip_compilation?: true

  Logger.debug("========================================")
  Logger.debug("rustler 编译")
  Logger.debug("混合环境 (MIX_ENV): #{Mix.env()}")
  Logger.debug("加载路径 (:load_from): #{inspect(@load_from)}")
  Logger.debug("========================================")

  def list_demo1(_list), do: error()
  def list_demo2(_list), do: error()
  def tuple_demo(_tuple), do: error()

  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
```

native/my_lib/src/demo_type.rs

```rust
use rustler::NifStruct;

#[derive(Debug, NifStruct)]
#[module = "DemoStruct"]
pub struct DemoStruct {
   pub name: String,
   pub age: i32,
}


use rustler::NifTuple;
use rustler::types::atom::Atom;

#[derive(NifTuple)]
pub struct DemoTuple {
   pub aaa: Atom,
   pub bbb: Atom
}
```

native/my_lib/src/lib.rs

```rust
#[rustler::nif(schedule = "DirtyCpu")]
fn list_demo1(list: Vec<i32>) -> Vec<i32> {
    println!("list in nif {:?}", list);
    return vec![111, 222, 333, 444, 555]
}
// ----------------------------------------------
pub mod demo_type;

#[rustler::nif(schedule = "DirtyCpu")]
fn list_demo2(list: Vec<demo_type::DemoStruct>) -> String {
    println!("list in nif {:?}", list);

    if let Some(last_person) = list.last(){
        return last_person.name.to_string();
    }else{
        return "".to_string();
    }
}
// ----------------------------------------------

#[rustler::nif(schedule = "DirtyCpu")]
fn tuple_demo(tuple: demo_type::DemoTuple) -> demo_type::DemoTuple {
    return tuple;
}

rustler::init!("Elixir.MyLib");
```

### zigbuild

zigbuild.ex

```elixir
defmodule Mix.Tasks.Zigbuild do
  use Mix.Task

  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [crate: :string, target: :string])

    crate = opts[:crate] || default_crate!()

    cargo_args = [
      "zigbuild",
      "--release",
      "-p",
      crate,
      "--message-format",
      "json"
    ]

    cargo_args =
      if target = opts[:target] do
        cargo_args ++ ["--target", target]
      else
        cargo_args
      end

    crate_dir = "native/#{crate}"
    output = "priv/native/#{crate}.so"

    unless File.dir?(crate_dir) do
      Mix.raise("Crate directory not found: #{crate_dir}")
    end

    File.mkdir_p!("priv/native")

    case System.cmd(
           "cargo",
           cargo_args,
           cd: crate_dir,
           stderr_to_stdout: true,
           into: ""
         ) do
      {result, 0} ->
        so_path = find_so(result, crate)

        unless so_path do
          Mix.raise("Could not find .so in cargo zigbuild output for crate: #{crate}")
        end

        File.cp!(so_path, output)
        Mix.shell().info("编译成功，运行以下命令检查 glibc 版本")
        Mix.shell().info("objdump -p #{output} | rg GLIBC_")

      {result, exit_code} ->
        Mix.raise("""
        cargo zigbuild failed with exit code #{exit_code}:

        #{result}
        """)
    end
  end

  defp default_crate! do
    native_dir = "native"

    unless File.dir?(native_dir) do
      Mix.raise("No native/ directory found")
    end

    native_dir
    |> File.ls!()
    |> Enum.reject(&String.starts_with?(&1, "."))
    |> case do
      [] -> Mix.raise("No crate directories found in native/")
      [crate] -> crate
      crates ->
        Mix.raise("""
        Multiple crate directories found in native/: #{inspect(crates)}
        Please specify the crate with --crate <name>
        """)
    end
  end

  defp find_so(output, crate) do
    output
    |> String.split("\n")
    |> Enum.find_value(fn line ->
      case JSON.decode(line) do
        {:ok, %{"reason" => "compiler-artifact", "filenames" => filenames, "target" => target}}
        when is_list(filenames) ->
          kind = target["kind"] || []

          if "cdylib" in kind && target["name"] == crate do
            Enum.find(filenames, &String.ends_with?(&1, ".so"))
          end

        _ ->
          nil
      end
    end)
  end
end
```

### 编译

```sh
mix zigbuild
# 指定 target
# mix zigbuild --crate my_lib --target x86_64-unknown-linux-gnu.2.17

mix compile
MIX_ENV=prod mix compile

# 打包
MIX_ENV=prod mix release
```
