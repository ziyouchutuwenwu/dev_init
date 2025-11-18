# umbrella

## 说明

umbrella 在发布的时候，需要明确指定子项目名称

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
    .........
    releases: releases()
  ]
end

defp releases do
  [
    aaa: [
      applications: [
        demo1: :permanent,
        demo2: :permanent
      ]
    ]
  ]
end
```

### 发布

最终需要的目录

```sh
_build/prod/rel/$RELEASE_NAME/
```

### 其它

参考普通项目发布
