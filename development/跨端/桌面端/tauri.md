# tauri

## 说明

需要有 rust 开发环境

## 用法

创建项目

```sh
npm create tauri-app
```

打包

```sh
npm run tauri build
```

生成 appimage 的时候，很可能会失败，但是编译已经成功了，路径在

```sh
src-tauri/target/release/
```

## 框架集成

创建项目的时候，可以选择框架

angular 的 src 目录直接复制过去，和 ng-zorro 等一些版本不一定一致，可能会遇到兼容问题

## 编译

不支持静态编译，因为很多 ui 库本生不支持

如果在 .cargo/config 里面配置的话，也暂时只支持一个平台
