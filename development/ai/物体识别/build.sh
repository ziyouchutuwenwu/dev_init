#!/bin/bash
set -e

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
ENCRYPTER_DIR="${ROOT_DIR}/encrypter"
DETECTOR_DIR="${ROOT_DIR}/detector"
SERVER_DIR="${ROOT_DIR}/server"
WEB_DIR="${ROOT_DIR}/web"
DEPLOY_DIR="${ROOT_DIR}/deploy"

build_encrypter() {
    echo "========================================================="
    echo "[1/5] 构建 encrypter (加密工具与授权库)..."
    echo "========================================================="
    cd "${ENCRYPTER_DIR}"
    chmod +x build.sh
    ./build.sh all

    echo ">> 复制 aarch64 静态库和头文件至 detector/3rdparty/model_license/ ..."
    mkdir -p "${DETECTOR_DIR}/3rdparty/model_license/lib" "${DETECTOR_DIR}/3rdparty/model_license/include"
    if [ -f "${ENCRYPTER_DIR}/zig-out/aarch64/lib/libmodel_license.a" ]; then
        cp -f "${ENCRYPTER_DIR}/zig-out/aarch64/lib/libmodel_license.a" "${DETECTOR_DIR}/3rdparty/model_license/lib/libmodel_license.a"
    fi
    if [ -f "${ENCRYPTER_DIR}/zig-out/aarch64/include/model_license.h" ]; then
        cp -f "${ENCRYPTER_DIR}/zig-out/aarch64/include/model_license.h" "${DETECTOR_DIR}/3rdparty/model_license/include/model_license.h"
    elif [ -f "${ENCRYPTER_DIR}/tools/gen_header.zig" ]; then
        zig run "${ENCRYPTER_DIR}/tools/gen_header.zig" -- "${DETECTOR_DIR}/3rdparty/model_license/include/model_license.h"
    fi
}

build_detector() {
    echo "========================================================="
    echo "[2/5] 交叉编译 C++ 检测核心库 detector..."
    echo "========================================================="
    cd "${DETECTOR_DIR}"
    chmod +x build.sh
    ./build.sh

    echo ">> 复制 detector 可执行文件至 deploy/ ..."
    mkdir -p "${DEPLOY_DIR}"
    if [ -f "${DETECTOR_DIR}/build/detector" ]; then
        cp -f "${DETECTOR_DIR}/build/detector" "${DEPLOY_DIR}/detector"
    fi
}

build_server() {
    echo "========================================================="
    echo "[3/5] 交叉编译 Rust 服务端 server..."
    echo "========================================================="
    cd "${SERVER_DIR}"
    chmod +x build.sh
    ./build.sh

    echo ">> 复制 server 可执行文件至 deploy/ ..."
    mkdir -p "${DEPLOY_DIR}"
    if [ -f "${SERVER_DIR}/target/aarch64-unknown-linux-gnu/release/server" ]; then
        cp -f "${SERVER_DIR}/target/aarch64-unknown-linux-gnu/release/server" "${DEPLOY_DIR}/server"
    fi
}

build_web() {
    echo "========================================================="
    echo "[4/5] 构建 Web 静态资源与模板..."
    echo "========================================================="
    if [ -d "${WEB_DIR}" ]; then
        cd "${WEB_DIR}"
        mix compile
        mix esbuild web
    fi
}

package_deploy() {
    echo "========================================================="
    echo "[5/5] 组装发布依赖并打包为 deploy.tar.gz..."
    echo "========================================================="
    mkdir -p "${DEPLOY_DIR}/lib" "${DEPLOY_DIR}/model"

    if [ -f "${DETECTOR_DIR}/3rdparty/rknn_model_zoo/3rdparty/rknpu2/Linux/aarch64/librknnrt.so" ]; then
        cp -f "${DETECTOR_DIR}/3rdparty/rknn_model_zoo/3rdparty/rknpu2/Linux/aarch64/librknnrt.so" "${DEPLOY_DIR}/lib/"
    fi
    if [ -f "${DETECTOR_DIR}/3rdparty/rknn_model_zoo/3rdparty/librga/Linux/aarch64/librga.so" ]; then
        cp -f "${DETECTOR_DIR}/3rdparty/rknn_model_zoo/3rdparty/librga/Linux/aarch64/librga.so" "${DEPLOY_DIR}/lib/"
    fi

    if [ -f "${ROOT_DIR}/config.yaml" ]; then
        cp -f "${ROOT_DIR}/config.yaml" "${DEPLOY_DIR}/config.yaml"
    elif [ -f "${SERVER_DIR}/config.yaml" ] && [ ! -f "${DEPLOY_DIR}/config.yaml" ]; then
        cp -f "${SERVER_DIR}/config.yaml" "${DEPLOY_DIR}/config.yaml"
    fi

    if [ ! -f "${DEPLOY_DIR}/license.key" ] && [ -f "${ROOT_DIR}/license.key" ]; then
        cp -f "${ROOT_DIR}/license.key" "${DEPLOY_DIR}/license.key"
    fi

    rm -f "${DEPLOY_DIR}/README.md"
    rm -f "${DEPLOY_DIR}/detect_cli"
    rm -f "${DEPLOY_DIR}/model.enc"
    rm -f "${DEPLOY_DIR}"/.*.stamp "${DEPLOY_DIR}"/*.stamp "${DEPLOY_DIR}"/????-????-????-???? 2>/dev/null || true

    cd "${ROOT_DIR}"
    tar -czvf deploy.tar.gz \
        --exclude='deploy/package.sh' \
        --exclude='deploy/detect_cli' \
        --exclude='deploy/*.rknn' \
        --exclude='deploy/.*.stamp' \
        --exclude='deploy/*.stamp' \
        deploy/

    echo "========================================================="
    echo "一键构建与打包全部完成！"
    echo "发布目录路径: ${DEPLOY_DIR}"
    echo "发布压缩包  : ${ROOT_DIR}/deploy.tar.gz"
    echo "========================================================="
}

TARGET="${1:-all}"

case "${TARGET}" in
    encrypter)
        build_encrypter
        ;;
    detector)
        build_detector
        ;;
    server)
        build_server
        ;;
    web)
        build_web
        ;;
    package)
        package_deploy
        ;;
    all|*)
        build_encrypter
        build_detector
        build_server
        build_web
        package_deploy
        ;;
esac
