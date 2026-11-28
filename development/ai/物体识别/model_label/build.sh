#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}"

# 清理旧输出，防止模块重命名等历史文件残留
rm -rf zig-out

# 仅构建 aarch64 目标平台 (RK3588)，不再需要 x86
zig build -Dtarget=aarch64-linux-gnu -Doptimize=ReleaseSafe --prefix zig-out/aarch64

DET_DIR="../detector"
if [ ! -d "${DET_DIR}" ] && [ -d "../../src/detector" ]; then
    DET_DIR="../../src/detector"
fi
mkdir -p "${DET_DIR}/3rdparty/model_label/include" "${DET_DIR}/3rdparty/model_label/lib"
cp -f include/model_label.h "${DET_DIR}/3rdparty/model_label/include/"
cp -f zig-out/aarch64/lib/libmodel_label.a "${DET_DIR}/3rdparty/model_label/lib/"

