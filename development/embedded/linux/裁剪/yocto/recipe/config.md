# config

## 说明

需要 执行 `configure` 的项目

## 例子

### 目录结构

```sh
recipes-demo
└── ddd
    ├── ddd_1.0.bb
    └── files
        └── source
            ├── AUTHORS
            ├── ChangeLog
            ├── configure.ac
            ├── COPYING
            ├── dd.c
            ├── Makefile.am
            ├── NEWS
            └── README
```

configure.ac

```sh
AC_INIT([ddd], [1.0], [you@example.com])
AM_INIT_AUTOMAKE
AC_PROG_CC
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
```

Makefile.am

```sh
bin_PROGRAMS = dd
dd_SOURCES = dd.c
```

ddd_1.0.bb

```sh
DESCRIPTION = "configure demo"
SECTION = "examples"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit autotools

SRC_URI = "file://source/dd.c \
           file://source/configure.ac \
           file://source/Makefile.am \
           file://source/AUTHORS \
           file://source/ChangeLog \
           file://source/NEWS \
           file://source/README \
           file://source/COPYING \
           "

S = "${WORKDIR}/source"
```

### rootfs

同 single 配置

### 执行

最后生成的不是 `/bin/dd`, 是 `/usr/bin/dd`

```sh
bitbake core-image-minimal -c cleanall; bitbake core-image-minimal; runqemu qemux86-64
```
