# ssh

## 说明

[地址](https://github.com/bitcrowd/sshkit.ex)

## 用法

ssher.ex

```elixir
defmodule SSHer do
  require Logger

  @default_pubkey_path "~/.ssh/id_rsa.pub"

  def upload_pubkey(host, user, opts \\ []) do
    pubkey_path = Keyword.get(opts, :pubkey_path, @default_pubkey_path) |> Path.expand()
    port = Keyword.get(opts, :port, 22)
    password = Keyword.get(opts, :password, nil)

    with {:ok, pubkey} <- File.read(pubkey_path),
         pubkey_trimmed = String.trim(pubkey),
         encoded = Base.encode64(pubkey_trimmed),
         context <-
           SSHKit.context(
             to_string(host),
             if(password,
               do: [user: user, password: password, silently_accept_hosts: true, port: port],
               else: [
                 user: user,
                 key_cb: {:ssh_agent, []},
                 silently_accept_hosts: true,
                 port: port
               ]
             )
           ),
         {:ok, out} <- insert_pubkey_to_keyfile(context, encoded) do
      Logger.info("公钥上传成功: #{host}")
      {:ok, out}
    else
      {:error, reason} = err ->
        Logger.error("上传公钥失败: #{inspect(reason)}")
        err

      :error ->
        {:error, :cannot_read_pubkey}
    end
  end

  defp insert_pubkey_to_keyfile(context, encoded_pubkey) do
    cmd = """
    mkdir -p ~/.ssh && chmod 700 ~/.ssh && \
    touch ~/.ssh/authorized_keys && \
    printf '%s' #{encoded_pubkey} | base64 -d | \
    ( grep -qxF - ~/.ssh/authorized_keys || tee -a ~/.ssh/authorized_keys > /dev/null ) && \
    chmod 600 ~/.ssh/authorized_keys
    """

    case SSHKit.run(context, cmd) do
      results when is_list(results) ->
        Enum.each(results, fn
          {:ok, streams, 0} ->
            Logger.debug("远端执行成功: #{inspect(streams)}")

          {:ok, streams, code} ->
            Logger.error("远端执行失败，退出码 #{code}, 输出: #{inspect(streams)}")

          other ->
            Logger.error("未知返回: #{inspect(other)}")
        end)

        {:ok, results}
    end
  end
end
```

```elixir
defmodule Demo do
  require Logger

  def demo1 do
    host = "10.0.2.199"
    user = "root"
    password = "123456"

    {:ok, conn} =
      SSHKit.SSH.connect(
        host,
        user: user,
        password: password,
        # port: 22,
        silently_accept_hosts: true
      )

    conn |> SSHKit.SSH.run("ifconfig")
  end

  def demo2 do
    host = "10.0.2.199"
    user = "root"

    context =
      SSHKit.context(
        host,
        user: user,
        key_cb: {:ssh_agent, []}
      )

    context |> SSHKit.run("ifconfig")
  end

  def demo3 do
    host = "10.0.2.199"
    user = "root"
    password = "root123456"

    opts = [
      password: password,
      pubkey_path: System.get_env("HOME") |> Path.join("downloads/key.pub")
    ]

    SSHer.upload_pubkey(host, user, opts)
  end
end
```
