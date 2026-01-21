# umbrella

## 用法

项目大了以后，db 和 web 等希望独立出来

### 创建

```sh
mix new umbrella_demo --umbrella
cd umbrella_demo/apps

# 普通子项目
mix new demo1

# phoenix 子项目
mix phx.new.web demo_web
# ecto 子项目
mix phx.new.ecto demo_ecto
```

### 依赖

共享依赖，放在顶层的 mix.exs

子项目依赖，放在子项目里面的 mix.exs

### 配置

默认只读取最外层配置，建议拆分

在顶层 config 目录里面拆，具体见配置分离文档

### app 自启动

需要自动启动的 application, 在子项目的 mix.exs 里面修改
