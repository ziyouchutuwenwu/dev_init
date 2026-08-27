# ssh

## 说明

[地址](https://github.com/bitcrowd/sshkit.ex)

## 用法

```elixir
defmodule SSH do
  require Logger

  @default_pubkey "~/.ssh/id_rsa.pub"

  def upload_pubkey(host, opts) when is_list(opts) do
    upload_pubkey(host, nil, nil, nil, opts)
  end

  def upload_pubkey(host, user \\ nil, password \\ nil, pubkey \\ nil, opts \\ []) do
    # 从参数取，不传则从 opts 取
    user = user || Keyword.get(opts, :user, nil)
    pubkey = pubkey || Keyword.get(opts, :pubkey, @default_pubkey) |> Path.expand()
    password = password || Keyword.get(opts, :password, nil)

    port = Keyword.get(opts, :port, 22)

    options =
      if password do
        [
          user: user,
          password: password,
          silently_accept_hosts: true,
          port: port
        ]
      else
        [
          user: user,
          key_cb: {:ssh_agent, []},
          silently_accept_hosts: true,
          port: port
        ]
      end

    with {:ok, pubkey} <- File.read(pubkey),
         pubkey_trimmed = String.trim(pubkey),
         encoded = Base.encode64(pubkey_trimmed),
         context <- SSHKit.context(to_string(host), options),
         {:ok, out} <- _insert_pubkey_to_keyfile(context, encoded) do
      Logger.info("公钥上传成功: #{host}")
      {:ok, out}
    else
      {:error, reason} = err ->
        Logger.error("上传公钥失败: #{inspect(reason)}")
        err
    end
  end

  defp _insert_pubkey_to_keyfile(context, encoded_pubkey) do
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

  def pwd_demo do
    host = "10.0.2.181"
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

  def ssh_agent_demo do
    host = "10.0.2.181"
    user = "root"

    context =
      SSHKit.context(
        host,
        user: user,
        key_cb: {:ssh_agent, []}
      )

    context |> SSHKit.run("ifconfig")
  end

  def pubkey_demo1 do
    host = "10.0.2.181"
    user = "root"
    password = "123456"
    pubkey = System.get_env("HOME") |> Path.join("downloads/key.pub")

    SSH.upload_pubkey(host, user, password, pubkey)
  end

  def pubkey_demo2 do
    host = "10.0.2.181"
    user = "root"
    password = "123456"
    pubkey = System.get_env("HOME") |> Path.join("downloads/key.pub")

    opts = [
      user: user,
      password: password,
      pubkey: pubkey
    ]

    SSH.upload_pubkey(host, opts)
  end
end
```
