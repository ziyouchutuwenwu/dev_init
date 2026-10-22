#!/bin/bash
set -e

cd "$(dirname "$0")"

ROOT_DIR="$(cd .. && pwd)"
TOOLCHAIN_BIN="${ROOT_DIR}/extra/toolchain/bin"
if [ -d "${TOOLCHAIN_BIN}" ]; then
    export PATH="${TOOLCHAIN_BIN}:$PATH"
    export CC_aarch64_unknown_linux_gnu="${TOOLCHAIN_BIN}/aarch64-none-linux-gnu-gcc"
    export AR_aarch64_unknown_linux_gnu="${TOOLCHAIN_BIN}/aarch64-none-linux-gnu-ar"
    export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER="${TOOLCHAIN_BIN}/aarch64-none-linux-gnu-gcc"
fi

cargo build --release --target=aarch64-unknown-linux-gnu "$@"
