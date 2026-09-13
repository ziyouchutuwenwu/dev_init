#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}"

TOOLCHAIN_BIN="$(cd "${SCRIPT_DIR}/../rknn/toolchain/bin" && pwd 2>/dev/null || true)"
if [ -d "${TOOLCHAIN_BIN}" ]; then
    export PATH="${TOOLCHAIN_BIN}:${PATH}"
    export CC_aarch64_unknown_linux_gnu="aarch64-none-linux-gnu-gcc"
    export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER="aarch64-none-linux-gnu-gcc"
fi

RUSTFLAGS="-C link-arg=-Wl,--allow-shlib-undefined" cargo build --release --target=aarch64-unknown-linux-gnu