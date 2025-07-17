# rustler

## 说明

[地址](https://github.com/rusterlium/rustler)

## 步骤

### 创建项目

```sh
mix new demo
```

### 添加依赖

mix.exs

```elixir
{:rustler, "~> 0.34.0", runtime: false}
```

```sh
mix deps.get
```

### 创建 crate

```sh
mix rustler.new --module MyLib --name my_lib --opt-app demo
```

### elixir 代码

config/config.exs

```elixir
import Config

config :demo, mode: config_env()
import_config "#{config_env()}.exs"
```

config/dev.exs

```elixir
import Config

config :demo,
  skip_ruster_on_compile: false,
  load_from: {:demo, "priv/native/libmy_lib"}
```

config/prod.exs

```elixir
import Config

config :demo,
  skip_ruster_on_compile: true,
  load_from: {:demo, "priv/native/libmy_lib"}
```

demo_struct.ex

```elixir
defmodule DemoStruct do
  defstruct [:name, :age]

  def new(name, age) do
    %__MODULE__{name: name, age: age}
  end
end
```

lib/demo.ex

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

lib/my_lib.ex

```elixir
defmodule MyLib do
  use Rustler,
    otp_app: :demo,
    crate: "my_lib",
    skip_compilation?: Application.compile_env(:demo, :skip_ruster_on_compile),
    load_from: Application.compile_env(:demo, :load_from)

  def list_demo1(_list), do: error()
  def list_demo2(_list), do: error()
  def tuple_demo(_tuple), do: error()

  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
```

### rust 代码

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

### 本地编译

```sh
mix compile
MIX_ENV=prod mix compile
```

### 发布

native/my_lib/.cargo/config.toml

```ini
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "https://mirrors.ustc.edu.cn/crates.io-index"
```

Dockerfile

```dockerfile
# nif 构建
FROM rust:1.73 as rust_build

ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup

WORKDIR /build
COPY native/my_lib ./
RUN cargo rustc --release

# elixir 构建
FROM elixir:1.15-slim as elixir_build

WORKDIR /build

COPY . .
COPY --from=rust_build /build/target/release/libmy_lib.so priv/native/

ENV HEX_UNSAFE_HTTPS=1 HEX_MIRROR="https://hexpm.upyun.com"

RUN mix local.hex --force && \
  mix local.rebar --force && \
  mix deps.get --only prod && \
  MIX_ENV=prod mix release

# 发布
FROM debian:stable-20221004-slim as app

# 用于网络调试
# RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
# RUN apt update; apt upgrade -y; apt install -y netcat curl iputils-ping net-tools

WORKDIR /app
COPY --from=elixir_build /build/_build/prod/rel/demo ./

ENTRYPOINT [ "bin/demo", "start" ]
```
