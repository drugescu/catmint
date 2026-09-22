#!/bin/sh
# Derive a host-portable runtime from the committed Linux runtime IR.
#
# runtime.ll was produced by clang on x86_64 Linux from a catmint_runtime.c
# that is NOT in this repository. Two things in it are not portable:
#   * a hardcoded x86_64-pc-linux-gnu target triple + datalayout, which makes
#     lli/clang try to codegen for the wrong architecture;
#   * __isoc99_scanf, a glibc-only alias for scanf.
# Dropping the target lines lets LLVM fall back to the host defaults.
#
# Usage: ./make-host-runtime.sh [in.ll] [out.ll]
set -e
IN=${1:-runtime.ll}
OUT=${2:-runtime.host.ll}
#   * per-function "target-cpu"="x86-64" / "target-features"="+sse2,..."
#     attributes, which the AArch64 backend rejects with a warning per call.
sed -e '/^target datalayout/d' \
    -e '/^target triple/d' \
    -e 's/__isoc99_scanf/scanf/g' \
    -e 's/"target-cpu"="[^"]*"//g' \
    -e 's/"target-features"="[^"]*"//g' \
    -e 's/"tune-cpu"="[^"]*"//g' \
    "$IN" > "$OUT"
echo "Wrote $OUT (host-portable runtime)"
