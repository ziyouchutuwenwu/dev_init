# tauri

需要有 rust 开发环境

## 步骤

### 创建项目

```sh
cargo install create-tauri-app
cargo create-tauri-app
```

或者

```sh
npm create tauri-app
```

### 运行

```sh
npm i
npm run tauri dev
```

### 打包

```sh
npm run tauri build
```

生成 appimage 的时候，很可能会失败，但是编译已经成功了，路径在

```sh
src-tauri/target/release/
```

## 注意

### ng-zorro 项目

- angular 的 src 目录直接复制过去

- 修改 angular.json
  inlineStyleLanguage
  styles

- 如果说找不到 antd, 可以手动 `ng add ng-zorro-antd`

- 注意在 package.json 里面添加依赖库，可以手动 npm install 或者抄过来

### 编译

不支持静态编译，因为很多 ui 库本生不支持

如果在 .cargo/config 里面配置的话，也暂时只支持一个平台
