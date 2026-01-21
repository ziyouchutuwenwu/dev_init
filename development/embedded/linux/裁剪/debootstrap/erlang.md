# erlang

## 说明

用 debtootstrap 生成 release, 复制对应的动态库

测试用 buildroot，理论上支持任何的 linux

## 注意

指令集要一致，armhf 和 armel 不一样

glibc 版本要注意

## 配置

### debtootstrap

get_libs.sh

```sh
#!/bin/sh

ERL_RELEASE_DIR="/opt/erl_demo"
TARGET_LIB_DIR="/opt/beam_libs"

# 需要排除的 glibc 相关库的正则
EXCLUDE_LIBS="libc\.so|libm\.so|ld-linux|libpthread\.so|librt\.so"

mkdir -p "$TARGET_LIB_DIR"

# 查找所有动态链接的 ELF 文件
find "$ERL_RELEASE_DIR" -type f | while read binfile; do
    if file "$binfile" | grep -q 'ELF.*dynamically linked'; then
        echo "分析 $binfile 的依赖库..."
        ldd "$binfile" | awk '{print $3}' | grep '^/' | grep -vE "$EXCLUDE_LIBS" | while read lib; do
            # 复制符号链接本身
            if [ -L "$lib" ]; then
                cp -av "$lib" "$TARGET_LIB_DIR/"
                # 复制符号链接指向的真实文件
                realfile=$(readlink -f "$lib")
                if [ -f "$realfile" ]; then
                    cp -av "$realfile" "$TARGET_LIB_DIR/"
                fi
            else
                # 复制普通文件
                cp -av "$lib" "$TARGET_LIB_DIR/"
            fi
        done
    fi
done

echo "所有依赖库（不含 glibc 相关）已复制到 $TARGET_LIB_DIR"
```

### buildroot

设置文件系统的 overlay

libs.sh

```sh
#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

export LD_LIBRARY_PATH=$CURRENT_DIR/beam_libs/:$LD_LIBRARY_PATH
# export LD_LIBRARY_PATH=/opt/beam_libs/:$LD_LIBRARY_PATH
```
