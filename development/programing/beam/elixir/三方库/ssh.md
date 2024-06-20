# ssh

```sh
https://github.com/bitcrowd/sshkit.ex
```

用法

```elixir
defmodule Demo do
  def demo do
    {:ok, conn} =
      SSHKit.SSH.connect("localhost",
        port: 22,
        user: "mmc",
        password: "123456",
        # 第一次 ssh 的时候，默认会提示是否保存 key 之类的，这个默认 yes
        silently_accept_hosts: true
      )

    downloads_dir = System.user_home() |> Path.join("downloads")

    {:ok, output, status} = SSHKit.SSH.run(conn, "cd #{downloads_dir}; tree")

    Enum.each(output, fn
      {:stdout, data} -> IO.write(data)
      {:stderr, data} -> IO.write([IO.ANSI.red(), data, IO.ANSI.reset()])
    end)

    IO.puts("status: #{status}")

    tmp_dir = System.tmp_dir()

    :ok = SSHKit.SCP.upload(conn, ".", "#{tmp_dir}", recursive: true)
    :ok = SSHKit.SSH.close(conn)
  end
end
```
