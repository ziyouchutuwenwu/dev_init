# cmake

## 例子

### 目录结构

```sh
recipes-demo
└── ccc
    ├── ccc_1.0.bb
    └── files
        └── source
            ├── cc.c
            └── CMakeLists.txt
```

ccc_1.0.bb

```sh
DESCRIPTION = "cmake demo"
SECTION = "examples"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit cmake

SRC_URI = "file://source/cc.c \
           file://source/CMakeLists.txt \
           "

S = "${WORKDIR}/source"
```

CMakeLists.txt

```CMakeLists
cmake_minimum_required(VERSION 3.0)
project(ccc C)

add_executable(cc cc.c)
install(TARGETS cc RUNTIME DESTINATION bin)
```

### rootfs

同 single 配置

### 执行

```sh
bitbake core-image-minimal -c cleanall; bitbake core-image-minimal; runqemu qemux86-64
```
