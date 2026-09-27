#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOOLCHAIN_DIR="${SCRIPT_DIR}/../extra/toolchain"
if [ ! -d "${TOOLCHAIN_DIR}/bin" ] && [ -d "${SCRIPT_DIR}/../toolchain/bin" ]; then
    TOOLCHAIN_DIR="${SCRIPT_DIR}/../toolchain"
fi

if [ -d "${TOOLCHAIN_DIR}/bin" ]; then
    export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
    export CC=aarch64-none-linux-gnu-gcc
    export CXX=aarch64-none-linux-gnu-g++
fi

mkdir -p "${SCRIPT_DIR}/3rdparty/model_license/lib" "${SCRIPT_DIR}/3rdparty/model_license/include"
if [ -f "${SCRIPT_DIR}/../encrypter/zig-out/aarch64/lib/libmodel_license.a" ]; then
    cp -f "${SCRIPT_DIR}/../encrypter/zig-out/aarch64/lib/libmodel_license.a" "${SCRIPT_DIR}/3rdparty/model_license/lib/"
    zig run "${SCRIPT_DIR}/../encrypter/tools/gen_header.zig" -- "${SCRIPT_DIR}/3rdparty/model_license/include/model_license.h"
elif [ -f "${SCRIPT_DIR}/../encrypter/build.sh" ]; then
    (cd "${SCRIPT_DIR}/../encrypter" && ./build.sh aarch64)
    cp -f "${SCRIPT_DIR}/../encrypter/zig-out/aarch64/lib/libmodel_license.a" "${SCRIPT_DIR}/3rdparty/model_license/lib/"
    zig run "${SCRIPT_DIR}/../encrypter/tools/gen_header.zig" -- "${SCRIPT_DIR}/3rdparty/model_license/include/model_license.h"
fi

BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake "${SCRIPT_DIR}" \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_C_COMPILER="${CC:-aarch64-none-linux-gnu-gcc}" \
    -DCMAKE_CXX_COMPILER="${CXX:-aarch64-none-linux-gnu-g++}" \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)

if [ -d "${SCRIPT_DIR}/../deploy" ]; then
    echo "同步更新可执行文件至 ../deploy/ ..."
    cp -f "${BUILD_DIR}/detector" "${SCRIPT_DIR}/../deploy/detector"
fi
