# recipe

## 说明

创建完 layer 以后，就可以创建 recipe

## 调试准备

如果需要看临时文件

local.conf

```sh
# 注释掉
# INHERIT += "rm_work"
```

## 目录结构

具体定义见 layer.conf

一个 recipe 目录下，允许多个名字

bitbake 执行的时候，用的是带.bb 的不带版本号的名字

```sh
$ tree
.
├── conf
│   └── layer.conf
├── recipes-demo
│   └── aaa
│       ├── aaa_1.0.bb
│   └── bbb
│       ├── bbb_1.0.bb
```
