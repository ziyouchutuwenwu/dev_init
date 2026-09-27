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

sync_detector() {
    echo "========================================================="
    echo "  [同步] 部署板端静态库至 detector/3rdparty/model_license"
    echo "========================================================="
    DEST_DIR="${SCRIPT_DIR}/../detector/3rdparty/model_license"
    mkdir -p "${DEST_DIR}/lib" "${DEST_DIR}/include"
    if [ -f "zig-out/aarch64/lib/libmodel_license.a" ]; then
        cp -f zig-out/aarch64/lib/libmodel_license.a "${DEST_DIR}/lib/libmodel_license.a"
    fi
    zig run tools/gen_header.zig -- "${DEST_DIR}/include/model_license.h"
    echo "静态库与动态生成头文件部署完成！"
}

case "${TARGET}" in
    x64|x86_64)
        build_x64
        sync_detector
        ;;
    target|aarch64|arm64)
        build_target
        sync_detector
        ;;
    all|*)
        build_x64
        build_target
        sync_detector
        ;;
esac

echo "========================================================="
echo "全部构建与部署成功！"
echo "  • x64 CLI 工具 (用于加密模型/签发证书) : zig-out/x86_64/bin/"
echo "  • aarch64 静态库 (供板端 detector 链接) : ../detector/3rdparty/model_license/lib/libmodel_license.a"
echo "========================================================="
