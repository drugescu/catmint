#!/bin/sh
# Produce the runtime LLVM IR to link programs against.
#
# runtime.c is the source of the object model and the built-in classes, and
# is compiled for this host every time. The IR it produces must match what
# IRGenerator.cpp expects -- layouts, virtual table slot order, helper
# signatures -- so there is deliberately no second, pre-built copy that could
# drift out of step with it.
#
# Usage: ./build-runtime.sh [output.ll]
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${1:-"$HERE/runtime.host.ll"}

LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v clang 2>/dev/null || echo /opt/homebrew/opt/llvm@22/bin/clang)")}

"$LLVM_BIN/clang" -O0 -emit-llvm -S "$HERE/runtime.c" -o "$OUT"
