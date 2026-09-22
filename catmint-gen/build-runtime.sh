#!/bin/sh
# Produce the runtime LLVM IR to link programs against.
#
# runtime.c is the real source. When it is present it is compiled for this
# host, which is both correct and simpler than patching the committed IR.
#
# runtime.ll is the original, committed without its source and built for
# x86_64 Linux. It is kept as a fallback, and make-host-runtime.sh strips its
# target triple and glibc-only symbols so it can run elsewhere.
#
# Usage: ./build-runtime.sh [output.ll]
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${1:-"$HERE/runtime.host.ll"}

LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v clang 2>/dev/null || echo /opt/homebrew/opt/llvm@22/bin/clang)")}

if [ -f "$HERE/runtime.c" ]; then
  "$LLVM_BIN/clang" -O0 -emit-llvm -S "$HERE/runtime.c" -o "$OUT"
else
  "$HERE/make-host-runtime.sh" "$HERE/runtime.ll" "$OUT" >/dev/null
fi
