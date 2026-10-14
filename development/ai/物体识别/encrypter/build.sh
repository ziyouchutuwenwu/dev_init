#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

TARGET="${1:-all}"
cd "${SCRIPT_DIR}"


build_x64() {
    echo "========================================================="
    echo "  [1/2] 编译 x86_64 (宿主开发机架构: CLI 工具 + 静态库)"
    echo "========================================================="
    zig build -Dtarget=x86_64-linux-gnu -Doptimize=ReleaseSafe --prefix zig-out/x86_64
}

build_target() {
    echo "========================================================="
    echo "  [2/2] 编译 aarch64 (目标板端架构: ARM64 静态库 + 工具)"
    echo "========================================================="
    zig build -Dtarget=aarch64-linux-gnu -Doptimize=ReleaseSafe --prefix zig-out/aarch64
}

case "${TARGET}" in
    x64|x86_64)
        build_x64
        ;;
    target|aarch64|arm64)
        build_target
        ;;
    all|*)
        build_x64
        build_target
        ;;
esac

echo "========================================================="
echo "全部构建成功！"
echo "  • x64 工具/静态库     : zig-out/x86_64/"
echo "  • aarch64 工具/静态库 : zig-out/aarch64/"
echo "========================================================="
