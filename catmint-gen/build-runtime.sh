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
#   glibc. Within one OS the IR does not depend on the architecture, which
#   portability.sh checks by compiling it for both.
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
LLVM_DIS="$RUNTIME_LLVM_BIN/llvm-dis"

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

# The module is made independent of the machine that built it. No triple and
# no data layout, so it takes the host's when linked -- do not pin a layout:
# its mangling field decides whether symbols get a leading underscore, so a
# fixed one is wrong on Mach-O. No target-cpu or target-features, which clang
# pins to the builder ("apple-m1", "+neon"). And no probe-stack, which is
# worse than unportable: Apple clang puts "probe-stack"="__chkstk_darwin" on
# functions with a 4K buffer, and LLVM 22's AArch64 back end calls
# report_fatal_error on any value but "inline-asm". The module id and source
# name are normalised so the file does not carry anyone's build path.
#
# What the file says must not depend on who packaged the compiler. Two things
# did: `!llvm.ident`, which names the build ("Ubuntu clang version 16.0.6
# (23ubuntu4)"), so --check failed on a CI runner whose clang-16 was the same
# compiler under another build number; and the defaults a packager chooses.
# The ident is removed and the defaults are said out loud: position-independent
# code as a PIE on Linux, no stack protector there, and the protector on macOS,
# where it is the platform's own default. (Linux without one while macOS has
# it was an accident of those defaults, not a decision.)
case "$OS" in
  darwin) FLAGS="-fstack-protector" ;;
  *)      FLAGS="-fPIE -fno-stack-protector" ;;
esac

build() {
  tmp="$1.tmp.$$"
  # -O2, not -O0: at -O0 clang marks every function `optnone noinline`, and
  # nothing in the runtime could then be inlined into a program.
  # shellcheck disable=SC2086
  "$CLANG" -O2 $FLAGS -emit-llvm -S "$SOURCE" -o "$tmp.ll"
  sed -e '/^target datalayout = /d' \
      -e '/^!llvm\.ident = /d' \
      -e '/^![0-9]* = !{!"[^"]*clang version/d' \
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
    trap 'rm -f "$fresh" "$fresh.old.ll" "$fresh.new.ll"' EXIT
    build "$fresh"
    if cmp -s "$fresh" "$COMMITTED"; then
      echo "build-runtime: $COMMITTED is what runtime.c builds to"
    else
      echo "build-runtime: $COMMITTED differs from what runtime.c builds to" >&2
      echo "  built with: $("$CLANG" --version | head -1)" >&2
      echo "  Rebuild it with ./build-runtime.sh, with the same LLVM, and commit it." >&2
      # What differs, in the readable form: a bare "differs" sends you
      # rebuilding blind, and in CI the log may be the only thing there is.
      if [ -x "$LLVM_DIS" ]; then
        "$LLVM_DIS" "$COMMITTED" -o "$fresh.old.ll"
        "$LLVM_DIS" "$fresh" -o "$fresh.new.ll"
        shown=$(diff -u -I '^; ModuleID' "$fresh.old.ll" "$fresh.new.ll" | head -40 || true)
        printf '%s\n' "$shown" >&2
        if [ -n "$GITHUB_ACTIONS" ]; then
          # An annotation, which GitHub serves without signing in.
          printf '::error title=runtime differs::%s\n' \
            "$(printf '%s' "$shown" | head -12 | sed -e 's/%/%25/g' | awk 'BEGIN{ORS="%0A"}1')"
        fi
      fi
      exit 1
    fi
    ;;
esac
