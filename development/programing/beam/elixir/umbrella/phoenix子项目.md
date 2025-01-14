# phoenix 子项目

## 说明

项目大了以后，db 和 web 等希望独立出来

## 步骤

```sh
mix new demo_apps --umbrella
cd apps
mix phx.new.web demo_web
```
