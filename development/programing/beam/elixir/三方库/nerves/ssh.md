# ssh

## 说明

配置免密登录

## 配置

config/target.exs

```elixir
# 支持多个公钥
keys = [
  Path.join([System.user_home!(), "./sda/服务器相关/天翼云/keys/key.pub"]),
]

existed_keys = Enum.filter(keys, &File.exists?/1)

if existed_keys == [] do
  Mix.raise("""
  找不到 ssh 公钥：
  #{Enum.join(keys, "\n")}
  """)
end

config :nerves_ssh,
  authorized_keys: Enum.map(existed_keys, &File.read!/1)
```
