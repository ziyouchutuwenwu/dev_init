# makefile

## 例子

### 目录结构

```sh
recipes-demo
└── bbb
    ├── bbb_1.0.bb
    └── files
        └── source
            ├── bb.c
            └── Makefile
```

bbb_1.0.bb

```sh
DESCRIPTION = "makefile demo"
SECTION = "examples"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://source/bb.c \
           file://source/Makefile \
           "
S = "${WORKDIR}/source"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 bb ${D}${bindir}
}
```

Makefile

```Makefile
TARGET = bb
all : $(TARGET)
CFLAGS ?= -wall -O
bindir = $(DESTDIR)/usr/bin/

OBJS = bb.o

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

install:
	install -d $(binddir)
	install -m 0755 $(TARGET) $(bindir)

uninstall:
	${RM} $(bindir)/$(TARGET)

clean:
	${RM} $(TARGET) $(OBJS)

.PHONY: all clean install uninstall
```

### rootfs

同 single 配置

### 执行

```sh
bitbake core-image-minimal -c cleanall; bitbake core-image-minimal; runqemu qemux86-64
```
