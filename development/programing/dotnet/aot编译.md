# aot 编译

## 步骤

创建项目

```sh
dotnet new console --use-program-main -n demo
```

修改工程 xxx.csproj

```xml
<PublishAot>true</PublishAot>
```

编译

```sh
dotnet publish -c release --self-contained
```
