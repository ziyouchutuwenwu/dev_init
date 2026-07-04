# buildroot

## 说明

用 debtootstrap 生成 release, 复制对应的动态库

测试用 buildroot，理论上支持任何的 linux

指令集要一致，armhf 和 armel 不一样

glibc 版本要注意

## 配置

### vm

虚拟机里面

copy_libs.sh

```sh
#!/bin/sh

if [ $# -ne 2 ]; then
    echo "使用说明: $0 <srcdir_to_check> <lib_save_dir>" >&2
    echo "示例:     $0 /path/to/project /path/to/output_libs" >&2
    exit 1
fi

# 接收参数
srcdir_to_check="$1"
lib_save_dir="$2"

# glibc 核心库排除列表
EXCLUDE_LIBS="libc\.so|libm\.so|libpthread\.so|librt\.so|libdl\.so|libresolv\.so|libnss_|libutil\.so|libanl\.so|ld-linux|linux-vdso"

# 规范化源目录路径（自动转换相对路径为绝对路径）
srcdir_to_check=$(readlink -f "$srcdir_to_check" 2>/dev/null || echo "$srcdir_to_check")
if [ ! -d "$srcdir_to_check" ]; then
    echo "错误: 源目录 '$srcdir_to_check' 不是有效目录" >&2
    exit 1
fi

# 创建并规范化目标目录路径
mkdir -p "$lib_save_dir"
lib_save_dir=$(readlink -f "$lib_save_dir" 2>/dev/null || echo "$lib_save_dir")

echo "=========================================="
echo "源检查目录 (srcdir_to_check): $srcdir_to_check"
echo "库保存目录 (lib_save_dir)   : $lib_save_dir"
echo "=========================================="

# 临时文件安全管理（去除了所有特定业务前缀，改为通用前缀）
TEMP_LIST=$(mktemp -t elf_deps_libs.XXXXXX 2>/dev/null || mktemp)
BIN_LIST=$(mktemp -t elf_deps_bins.XXXXXX 2>/dev/null || mktemp)
trap 'rm -f "$TEMP_LIST" "$BIN_LIST"' EXIT INT TERM

echo "正在扫描 ELF 文件并解析依赖..."

# 检查系统关键命令是否存在
if ! command -v ldd >/dev/null 2>&1; then
    echo "错误: 系统中未找到 ldd 命令，无法解析依赖" >&2
    exit 1
fi

# 优化 1：收集源目录下所有动态链接的 ELF 文件，写入独立的临时列表
find "$srcdir_to_check" -type f -exec file {} + 2>/dev/null | \
    while IFS=: read -r filename fileinfo; do
        case "$fileinfo" in
            *"ELF"*"dynamically linked"*)
                echo "$filename" >> "$BIN_LIST"
                ;;
        esac
    done

# 优化 2：顺序读取文件，不使用管道连接，确保进程状态和错误捕捉 100% 生效
while read -r binfile; do
    [ -n "$binfile" ] || continue
    if [ ! -r "$binfile" ]; then
        echo "警告: 无法读取 $binfile" >&2
        continue
    fi

    # 显式捕获 ldd 的执行状态
    LDD_OUT=$(ldd "$binfile" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$LDD_OUT" ]; then
        echo "警告: ldd 解析 $binfile 失败" >&2
        continue
    fi

    # 解析并提取路径
    echo "$LDD_OUT" | awk '{
        if ($2 == "=>") { print $3 } else { print $1 }
    }' | grep '^/' | grep -vE "$EXCLUDE_LIBS" >> "$TEMP_LIST"
done < "$BIN_LIST"

if [ ! -s "$TEMP_LIST" ]; then
    echo "警告: 未找到任何需要复制的外部依赖库" >&2
    exit 0
fi

echo "共收集到 $(wc -l < "$TEMP_LIST") 个依赖记录，去重后处理..."

# 去重并智能复制
sort -u "$TEMP_LIST" | while read -r lib; do
    if [ ! -f "$lib" ]; then
        echo "警告: 库文件不存在 $lib" >&2
        continue
    fi

    realfile=$(readlink -f "$lib" 2>/dev/null)
    # 防御潜在的死循环或 readlink 异常
    if [ -z "$realfile" ] || [ ! -f "$realfile" ]; then
        echo "警告: 无法解析真实文件路径 $lib" >&2
        continue
    fi

    filename=$(basename "$lib")
    realname=$(basename "$realfile")

    echo "正在处理库: $filename -> $realname"

    # 复制真实文件（带错误恢复机制）
    if ! cp -pf "$realfile" "$lib_save_dir/$realname" 2>/dev/null; then
        echo "警告: cp -pf 失败，尝试普通复制 $realname" >&2
        if ! cp -f "$realfile" "$lib_save_dir/$realname" 2>/dev/null; then
            echo "错误: 无法复制文件 $realname" >&2
            continue
        fi
    fi

    # 重建安全的相对软链接
    if [ "$filename" != "$realname" ]; then
        if [ -e "$lib_save_dir/$filename" ] && [ ! -L "$lib_save_dir/$filename" ]; then
            echo "警告: $lib_save_dir/$filename 已存在且不是软链接，跳过链接创建" >&2
        else
            # 使用子 shell 局部切换目录，确保软链接目标是纯文件名，100% 绿色可移植
            (cd "$lib_save_dir" && ln -sf "$realname" "$filename")
        fi
    fi
done

echo "所有依赖库已成功、安全地复制到 $lib_save_dir"
echo "统计: $(find "$lib_save_dir" -type f | wc -l) 个库文件, $(find "$lib_save_dir" -type l | wc -l) 个软链接"
```

执行

```sh
./copy_libs.sh /opt/erl_demo /opt/beam_libs
```

### buildroot

把 TARGET_LIB_DIR 加到 LD_LIBRARY_PATH 里面

```sh
#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

export LD_LIBRARY_PATH=$CURRENT_DIR/beam_libs/:$LD_LIBRARY_PATH
```
