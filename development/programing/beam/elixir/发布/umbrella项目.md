# umbrella 项目

## 步骤

### 创建项目

```sh
mix new demo_apps --umbrella

cd demo_apps/apps
mix new demo1
mix new demo2
```

### 修改 mix.exs

根目录下的 mix.exs

```elixir
def project do
  [
    releases: [
      aaa: [
        applications: [
          demo1: :permanent,
          demo2: :permanent
        ]
      ],
      bbb: [
        applications: [demo2: :permanent]
      ]
    ],
    ....
  ]
end
```

### 其它

参考 [普通项目发布](./%E6%99%AE%E9%80%9A%E9%A1%B9%E7%9B%AE%E5%8F%91%E5%B8%83.md)
