#!/bin/sh
# Rebuild the prebuilt runtime from runtime.c. This is for people working on
# catmint: nothing a user runs calls it, and it is the one place clang is
# needed.
#
#   ./build-runtime.sh              rebuild runtime-<os>.bc beside runtime.c
#   ./build-runtime.sh --out F.bc   build into F.bc instead (the test suite)
#   ./build-runtime.sh --check      rebuild into a temporary file and fail if
#                                   it differs from the committed one
#
# The runtime ships as bitcode, one file per operating system:
#
# - Bitcode, not textual IR. The text format changes between LLVM major
#   versions -- `captures(none)` replaced `nocapture` in LLVM 21, and LLVM 18
#   could not read a runtime.ll written by 22 -- while newer LLVM reads older
#   bitcode by policy. So the runtime is built by the oldest LLVM catmint
#   supports and every newer one can link it. RUNTIME_LLVM_BIN chooses that
#   LLVM; the default is LLVM 16 when it is installed.
#
# - One per OS. The C library's headers are not neutral: built on macOS, the
#   IR calls `\01_fputs` and `\01_fopen` (Darwin's symbol aliases) and
#   `__maskrune` (its ctype), and `stdin`/`stderr` name different globals on
#   glibc. Within one OS one file runs on both architectures, which
#   portability.sh checks by compiling it for both -- but it is not *built*
#   the same on both, which is why the Linux one is built for arm64 wherever
#   it is built (see TARGET below).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
SOURCE="$HERE/runtime.c"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
COMMITTED="$HERE/runtime-$OS.bc"

MODE=build
OUT="$COMMITTED"
while [ $# -gt 0 ]; do
  case "$1" in
    --out)   OUT="$2"; MODE=out; shift 2 ;;
    --check) MODE=check; shift ;;
    *) echo "usage: build-runtime.sh [--out file.bc | --check]" >&2; exit 2 ;;
  esac
done

# The oldest supported LLVM if it is here, else the one catmintc uses.
if [ -z "$RUNTIME_LLVM_BIN" ]; then
  for candidate in /opt/homebrew/opt/llvm@16/bin /usr/local/opt/llvm@16/bin \
                   /usr/lib/llvm-16/bin; do
    if [ -x "$candidate/clang" ]; then RUNTIME_LLVM_BIN=$candidate; break; fi
  done
fi
if [ -z "$RUNTIME_LLVM_BIN" ]; then
  RUNTIME_LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || \
                                  echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
fi
CLANG="$RUNTIME_LLVM_BIN/clang"
LLVM_AS="$RUNTIME_LLVM_BIN/llvm-as"

if [ ! -x "$CLANG" ] || [ ! -x "$LLVM_AS" ]; then
  if [ "$MODE" = out ] && [ -f "$COMMITTED" ]; then
    # The test suite on a machine without clang tests what users get.
    cp "$COMMITTED" "$OUT"
    exit 0
  fi
  echo "build-runtime: needs clang and llvm-as in $RUNTIME_LLVM_BIN" >&2
  echo "  (only to rebuild the runtime; compiling catmint programs does not)" >&2
  exit 1
fi

# The Linux file is built for arm64, whatever machine builds it. Even with the
# triple and data layout taken out below, the IR clang writes keeps two
# choices of the machine it ran on: built on arm64, every function says
# "frame-pointer"="non-leaf", and arm64 gives the large global arrays 8-byte
# alignment where x86-64 gives them 16. So the file differed with the builder,
# and --check could pass only on the architecture that wrote it last -- the
# arm64 container on one side, x86-64 CI on the other. Built for one target
# everywhere, it is one file everywhere: on x86-64, pinned to arm64 and given
# arm64's headers, clang writes runtime-linux.bc byte for byte as the arm64
# container did. It runs on both, as it always has: the runtime uses neither
# of the things C lowers per target in the front end, varargs and long
# double, and portability.sh compiles it for both.
#
# On arm64 that target is the machine's own. Anywhere else clang needs arm64's
# C headers -- libc6-dev-arm64-cross and linux-libc-dev-arm64-cross on Debian
# and Ubuntu, or wherever ARM64_INCLUDE points. The Darwin file is not pinned:
# it has only ever been built on arm64.
TARGET=""
if [ "$OS" = linux ]; then
  TARGET="--target=aarch64-linux-gnu"
  case "$(uname -m)" in
    aarch64|arm64) ;;
    *)
      ARM64_INCLUDE=${ARM64_INCLUDE:-/usr/aarch64-linux-gnu/include}
      if [ -f "$ARM64_INCLUDE/stdio.h" ]; then
        TARGET="$TARGET -nostdlibinc -isystem $ARM64_INCLUDE"
      elif [ "$MODE" = out ]; then
        # Only --check and a rebuild need the exact bytes. The test suite
        # still gets the runtime.c being edited, compiled for this machine.
        echo "build-runtime: no arm64 headers in $ARM64_INCLUDE, so building for this machine" >&2
        TARGET=""
      else
        echo "build-runtime: runtime-linux.bc is built for arm64, and this machine needs arm64's C headers for that:" >&2
        echo "  sudo apt-get install libc6-dev-arm64-cross linux-libc-dev-arm64-cross" >&2
        echo "  (or set ARM64_INCLUDE to the directory holding them)" >&2
        exit 1
      fi ;;
  esac
fi

# The module is made independent of the machine that built it. No triple and
# no data layout, so it takes the host's when linked -- do not pin a layout:
# its mangling field decides whether symbols get a leading underscore, so a
# fixed one is wrong on Mach-O. No target-cpu or target-features, which clang
# pins to the builder ("apple-m1", "+neon"). And no probe-stack, which is
# worse than unportable: Apple clang puts "probe-stack"="__chkstk_darwin" on
# functions with a 4K buffer, and LLVM 22's AArch64 back end calls
# report_fatal_error on any value but "inline-asm". The module id and source
# name are normalised so the file does not carry anyone's build path.
build() {
  tmp="$1.tmp.$$"
  # -O2, not -O0: at -O0 clang marks every function `optnone noinline`, and
  # nothing in the runtime could then be inlined into a program.
  # shellcheck disable=SC2086
  "$CLANG" $TARGET -O2 -emit-llvm -S "$SOURCE" -o "$tmp.ll"
  sed -e '/^target datalayout = /d' \
      -e '/^target triple = /d' \
      -e 's/ "target-cpu"="[^"]*"//g' \
      -e 's/ "target-features"="[^"]*"//g' \
      -e 's/ "probe-stack"="[^"]*"//g' \
      -e 's/ "tune-cpu"="[^"]*"//g' \
      -e "s|^; ModuleID = .*|; ModuleID = 'runtime.c'|" \
      -e 's|^source_filename = .*|source_filename = "runtime.c"|' \
      "$tmp.ll" > "$tmp.clean.ll"
  "$LLVM_AS" "$tmp.clean.ll" -o "$1"
  rm -f "$tmp.ll" "$tmp.clean.ll"
}

case "$MODE" in
  build)
    build "$COMMITTED"
    echo "build-runtime: wrote $COMMITTED with $("$CLANG" --version | head -1)" >&2
    ;;
  out)
    build "$OUT"
    ;;
  check)
    fresh=$(mktemp)
    trap 'rm -f "$fresh"' EXIT
    build "$fresh"
    if cmp -s "$fresh" "$COMMITTED"; then
      echo "build-runtime: $COMMITTED is what runtime.c builds to"
    else
      echo "build-runtime: $COMMITTED differs from what runtime.c builds to" >&2
      echo "  built with: $("$CLANG" --version | head -1)" >&2
      echo "  Rebuild it with ./build-runtime.sh, with the same LLVM, and commit it." >&2
      exit 1
    fi
    ;;
esac
