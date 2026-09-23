#!/bin/sh
# Produce the runtime LLVM IR to link programs against.
#
# runtime.c is the source of truth. runtime.ll is a checked-in copy of what
# it compiles to, with the target triple and data layout stripped so that it
# works on any 64-bit host: the runtime uses only pointers, int, long long
# and double, whose layouts agree everywhere this compiler runs.
#
# With a C compiler available the .c is compiled fresh, and the checked-in
# .ll is refreshed whenever it has fallen behind. Without one, the .ll is
# used as it stands, which is the point of keeping it in the repository.
#
# Usage: ./build-runtime.sh [output.ll]
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${1:-"$HERE/runtime.host.ll"}
SOURCE="$HERE/runtime.c"
CHECKED_IN="$HERE/runtime.ll"

# llvm-link first, not clang: catmintc links and compiles with one toolchain,
# and the runtime has to be built by that same one. Picking clang off PATH
# instead is how a program ends up compiled by one vendor's front end and one
# vendor's back end, which do not always agree on what a function attribute
# means.
LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || \
                                  echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
CLANG="$LLVM_BIN/clang"

# A module with no triple and no data layout takes the host's, which is what
# makes one checked-in copy serve every machine. clang says so on every link,
# hence -Wno-override-module in catmintc.
#
# Do not be tempted to pin a data layout here instead: its mangling field
# decides whether symbols get a leading underscore, so a fixed one is wrong
# on Mach-O and the JIT then cannot resolve anything.
#
# The module id and source filename are normalised so the committed copy does
# not carry whoever's absolute build path.
# target-cpu and target-features go too. clang pins them to the machine it ran
# on -- "apple-m1", "+neon", "+sha3" -- and a copy carrying those is not a
# portable runtime, whatever the triple says.
#
# So does probe-stack, which is worse than unportable: Apple clang puts
# "probe-stack"="__chkstk_darwin" on the two functions here with a 4K buffer,
# and LLVM 22's AArch64 back end accepts only the value "inline-asm" and calls
# report_fatal_error on anything else. One vendor's front end and another's
# back end then cannot build hello world. Dropping it costs those two
# functions their stack-clash hardening, which for a 4K frame under a 16K
# guard page is nothing, and it makes the checked-in IR independent of
# whichever clang happened to produce it.
strip_target() {
  sed -e '/^target datalayout = /d' \
      -e '/^target triple = /d' \
      -e 's/ "target-cpu"="[^"]*"//g' \
      -e 's/ "target-features"="[^"]*"//g' \
      -e 's/ "probe-stack"="[^"]*"//g' \
      -e "s|^; ModuleID = .*|; ModuleID = 'runtime.c'|" \
      -e 's|^source_filename = .*|source_filename = "runtime.c"|' "$1" > "$2"
}

if [ -x "$CLANG" ] && [ -f "$SOURCE" ]; then
  TMP="$OUT.tmp.$$"
  # -O2, not -O0: at -O0 clang marks every function `optnone noinline`,
  # which stops the program that links against it from inlining anything --
  # every array element access stayed a function call because of it.
  "$CLANG" -O2 -emit-llvm -S "$SOURCE" -o "$TMP"
  strip_target "$TMP" "$OUT"
  rm -f "$TMP"

  # Keep the checked-in copy current, so the next person without a compiler
  # gets a runtime that matches this runtime.c rather than an older one.
  if [ ! -f "$CHECKED_IN" ] || [ "$SOURCE" -nt "$CHECKED_IN" ]; then
    cp "$OUT" "$CHECKED_IN"
    echo "build-runtime: refreshed $CHECKED_IN from runtime.c" >&2
  fi
  exit 0
fi

if [ -f "$CHECKED_IN" ]; then
  [ -f "$SOURCE" ] && [ "$SOURCE" -nt "$CHECKED_IN" ] && \
    echo "build-runtime: warning: runtime.c is newer than runtime.ll and no C compiler was found; using the checked-in IR" >&2
  cp "$CHECKED_IN" "$OUT"
  exit 0
fi

echo "build-runtime: neither a C compiler nor $CHECKED_IN is available" >&2
exit 1
