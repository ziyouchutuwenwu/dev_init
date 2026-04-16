# rpc

## 说明

远程调用

## 例子

### python

依赖

```sh
pymetasploit3
```

代码

```python
from pymetasploit3.msfrpc import *

def print_dir(object):
    if hasattr(object, '__dir__'):
        for module in dir(object):
          if not module.startswith('_'):
            print(module)
    else:
        print(" %s 无法获取其属性列表", object)

if __name__ == "__main__":
    client = MsfRpcClient('123456', username='mmc', server="127.0.0.1", port=55553, ssl=False)
    print_dir(client.modules.exploits)
```

### elixir

依赖

```elixir
{:msgpax, "~> 2.3"},
{:finch, "~> 0.16"}
```

msf_rpc.ex

```elixir
defmodule MsfRpc do
  @default_url "http://127.0.0.1:55553/api/"
  @finch MsfFinch

  def login(user, pass, url \\ @default_url) do
    body = Msgpax.pack!(["auth.login", user, pass])
    headers = [
      {"content-type", "binary/message-pack"},
      {"accept", "binary/message-pack"}
    ]
    Finch.start_link(name: @finch)
    req = Finch.build(:post, url, headers, body)
    case Finch.request(req, @finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        decoded = Msgpax.unpack!(body)
        cond do
          is_map(decoded) and Map.has_key?(decoded, "token") -> {:ok, decoded["token"]}
          is_map(decoded) and Map.has_key?(decoded, "result") -> {:ok, decoded["result"]}
          is_map(decoded) and Map.has_key?(decoded, "error") -> {:error, decoded["error"]}
          true -> {:error, decoded}
        end
      {:ok, resp} -> {:error, resp}
      {:error, reason} -> {:error, reason}
    end
  end

  def call(token, method, params \\ [], url \\ @default_url) do
    body = Msgpax.pack!([method, token | params])
    headers = [
      {"content-type", "binary/message-pack"},
      {"accept", "binary/message-pack"}
    ]
    req = Finch.build(:post, url, headers, body)
    case Finch.request(req, @finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        decoded = Msgpax.unpack!(body)
        cond do
          is_map(decoded) and Map.has_key?(decoded, "error") -> {:error, decoded["error"]}
          true -> {:ok, decoded}
        end
      {:ok, resp} -> {:error, resp}
      {:error, reason} -> {:error, reason}
    end
  end
end
```

demo.ex

```elixir
defmodule Demo do
  def demo do
    user = "mmc"
    pass = "123456"
    url = "http://127.0.0.1:55553/api/"
    case MsfRpc.login(user, pass, url) do
      {:ok, token} ->
        case MsfRpc.call(token, "module.exploits", [], url) do
          {:ok, result} -> result
          {:error, err} -> {:error, err}
        end
      {:error, err} -> {:error, err}
    end
  end
end
```
