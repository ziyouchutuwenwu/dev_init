# umbrella

## 说明

项目大了以后，db 和 web 等希望独立出来

## 项目创建

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

## 配置文件

只读取最外层配置
