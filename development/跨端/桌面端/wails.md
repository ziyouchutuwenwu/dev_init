# wails

## 步骤

### 安装

```sh
go install github.com/wailsapp/wails/v2/cmd/wails@latest
```

### 创建项目

```sh
wails init -n demo
```

### 框架集成

fronted 目录用任意 web 项目都可以，不需要提前打包，从操作方式看，最简单方便

### 编译

```sh
wails build
```

### 注意

如果发现某些 wails 命令丢失，直接在 package.json 里面添加即可，比如 dev, angular 里面默认没有
