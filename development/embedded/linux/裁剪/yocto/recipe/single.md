# single

## 例子

### 目录结构

`recipes-demo` 是从 `meta-skeleton/recipes-skeleton/hello-single` 里面抄过来的

```sh
$ tree
.
├── conf
│   └── layer.conf
├── recipes-demo
│   └── aaa
│       ├── aaa_1.0.bb
│       └── files
│           └── hello.c
```

### 编译

在 `build/tmp/work/core2-64-poky-linux/` 能看到结果

```sh
bitbake aaa
```

### rootfs

`core-image-minimal.bbappend`

- 不能换名字，因为依赖 `meta/recipes-core/images/core-image-minimal.bb`
- 可以放在 aaa_1.0.bb 同目录下
- 也可以另外创建一个 recipe，放进去，比如 `recipes-minimal/images/`

```sh
# aaa 是 recipe 的名字
IMAGE_INSTALL += "aaa"
```

### 执行

```sh
bitbake core-image-minimal -c cleanall; bitbake core-image-minimal; runqemu qemux86-64
```
