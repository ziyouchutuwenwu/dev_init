#!/bin/bash
set -e

cd "$(dirname "$0")"
cargo build --release --target=aarch64-unknown-linux-gnu "$@"
