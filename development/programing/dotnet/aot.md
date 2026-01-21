# aot

## 步骤

### 创建

```sh
dotnet new console --use-program-main -n demo
```

### 设置 aot

xx.csproj

```xml
<PropertyGroup>
  <PublishAot>true</PublishAot>
</PropertyGroup>
```

或者编译时加参数

```sh
# aot
/p:PublishAot=true

# 加入运行时需要的库
--self-contained
```

### 编译

```sh
# bin/release/netx.x/linux-x64/publish/
dotnet publish -c release /p:PublishSingleFile=true --self-contained
```

或者

```sh
# bin/release/netx.x/linux-x64/publish/
dotnet publish -c release /p:PublishAot=true /p:PublishSingleFile=true --self-contained
```
