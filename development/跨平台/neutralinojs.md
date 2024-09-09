# neutralinojs

## 说明

不需要在每个平台上单独编译，平台相关的 exe 会在项目创建的时候自动下载，下载比较慢。

## 用法

### cli

```sh
npm install -g @neutralinojs/neu
```

### 例子

下载不下来的话，使用 proxychians

```sh
neu create demo --template neutralinojs/neutralinojs-zero
cd demo
neu run
neu build --release
```

### 框架集成

其它前端框架打包以后的文件，放到 www 目录，重新打包即可
