#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOOLCHAIN_DIR="${SCRIPT_DIR}/../../extra/toolchain"
if [ ! -d "${TOOLCHAIN_DIR}/bin" ] && [ -d "${SCRIPT_DIR}/../extra/toolchain/bin" ]; then
    TOOLCHAIN_DIR="${SCRIPT_DIR}/../extra/toolchain"
elif [ ! -d "${TOOLCHAIN_DIR}/bin" ] && [ -d "${SCRIPT_DIR}/../toolchain/bin" ]; then
    TOOLCHAIN_DIR="${SCRIPT_DIR}/../toolchain"
fi

if [ -d "${TOOLCHAIN_DIR}/bin" ]; then
    export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
    export CC=aarch64-none-linux-gnu-gcc
    export CXX=aarch64-none-linux-gnu-g++
fi

if [ ! -f "${SCRIPT_DIR}/3rdparty/model_label/lib/libmodel_label.a" ] || [ ! -f "${SCRIPT_DIR}/3rdparty/model_label/include/model_label.h" ]; then
    echo "错误: 未找到 libmodel_label.a 或 model_label.h，请先构建 model_label 并同步依赖产物至 3rdparty/model_label"
    exit 1
fi

BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

if [ -f "CMakeCache.txt" ] && ! grep -q "${SCRIPT_DIR}" CMakeCache.txt; then
    rm -rf CMakeCache.txt CMakeFiles
fi

cmake "${SCRIPT_DIR}" \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_C_COMPILER="${CC:-aarch64-none-linux-gnu-gcc}" \
    -DCMAKE_CXX_COMPILER="${CXX:-aarch64-none-linux-gnu-g++}" \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
