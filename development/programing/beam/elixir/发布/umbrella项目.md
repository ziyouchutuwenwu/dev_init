# umbrella 项目

## 步骤

### 创建项目

```sh
mix new demo_apps --umbrella

cd demo_apps/apps
mix new demo1
mix new demo2
```

### mix.exs

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

参考普通项目发布
