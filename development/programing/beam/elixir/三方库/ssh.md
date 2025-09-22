# ssh

## 说明

[地址](https://github.com/bitcrowd/sshkit.ex)

## 用法

```elixir
defmodule Demo do
  require Logger

  def demo1 do
    context =
      SSHKit.context(
        "xx.xx.xx.xx",
        user: "root",
        key_cb: {:ssh_agent, []}
      )

    context
    |> SSHKit.run("ifconfig | grep 10.0.0.")
  end

  def demo2 do
    SSHKit.SSH.connect(
      "xx.xx.xx.xx",
      user: "root",
      # port: 22,
      # 第一次 ssh 的时候，默认会提示是否保存 key 之类的，这个默认 yes
      silently_accept_hosts: true
    )
  end
end
```
