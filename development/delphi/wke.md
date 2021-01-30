# wke

[gitee 地址](https://gitee.com/LangjiApp/Wke4Delphi)

## 步骤

### 编译控件

编译出来的 bpl 默认在

```sh
C:\Documents and Settings\All Users\Documents\RAD Studio\8.0\Bpl
```

### 安装控件

```sh
install component, 添加 bpl

tools
  options
    delphi options
      library
        library path
把 wke 编译出的 dcu 目录添加进去
```

## 注意

node.dll 需要和编译出来的 exe 放同一个目录
