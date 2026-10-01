#!/bin/sh
# Check that what this compiler emits is not pinned to the machine it ran on.
#
#   ./portability.sh
#
# Three questions, all answerable without another machine:
#
#   1. Do catmint's object layouts come out the same on every target? The
#      generator computes every instance's size with one fixed data layout
#      string and bakes the number into the run-time type information. If a
#      target disagreed, every allocation would be the wrong size, silently.
#      Asserted at compile time, so nothing has to run.
#   2. Do the prebuilt runtimes -- one bitcode file per OS, which is all a
#      user gets, since nothing compiles runtime.c for them -- compile for
#      both architectures of their OS, pinned to nothing? The old runtime.ll
#      once said "target-cpu"="apple-m1" on all thirty of its functions while
#      claiming to be portable.
#   3. Does a generated program's IR?
#
# What this cannot answer is whether the result *runs* on Linux. Only CI on a
# Linux box can say that; see .github/workflows/ci.yml.
set -e

ROOT=$(cd "$(dirname "$0")" && pwd)
LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || \
                                  echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
export LLVM_BIN
CLANG="$LLVM_BIN/clang"
GREEN='\033[1;32m'; RED='\033[1;31m'; NC='\033[0m'

TARGETS="x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu
         x86_64-apple-darwin arm64-apple-darwin"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
failed=0

# ---- 1. object layouts ----------------------------------------------------
cat > "$WORK/layout.c" <<'EOF'
/* The shapes catmint objects actually take. Every object is
   { rtti, int refs, fields... }; the run-time type information is
   { name, size, parent, interfaces, finalize, vtable[] }; and marshalToC
   reaches a String's characters and an array's elements at one fixed offset,
   which only holds if all four have the same shape. */
#include <stddef.h>
struct Obj     { void *rtti; int refs; };
struct OneInt  { void *rtti; int refs; int id; };
struct PtrInt  { void *rtti; int refs; void *handle; int size; };
struct Str     { void *rtti; int refs; int length; char *chars; };
struct Arr     { void *rtti; int refs; int length; long long *data; };
struct Rtti    { void *name; int size; void *parent; void *ifaces; void *fin;
                 void *vtable[]; };

_Static_assert(sizeof(struct Obj)    == 16, "Object");
_Static_assert(sizeof(struct OneInt) == 16, "a class with one Int field");
_Static_assert(sizeof(struct PtrInt) == 32, "a class with a Ptr and an Int");
_Static_assert(sizeof(struct Str)    == 24, "String");
_Static_assert(sizeof(struct Arr)    == 24, "Bytes, Ints and Floats");
_Static_assert(offsetof(struct Str, chars) == 16, "marshalToC offset");
_Static_assert(offsetof(struct Arr, data)  == 16, "marshalToC offset");
_Static_assert(sizeof(struct Rtti) == 40, "RTTI up to the vtable");
EOF

printf "object layouts\n"
for target in $TARGETS; do
  if "$CLANG" --target="$target" -c "$WORK/layout.c" -o /dev/null \
        2>"$WORK/log"; then
    printf "  %-30s ${GREEN}agree${NC}\n" "$target"
  else
    printf "  %-30s ${RED}DISAGREE${NC}\n" "$target"
    sed 's/^/      /' "$WORK/log" | head -4
    failed=1
  fi
done

# ---- 2. the prebuilt runtimes ---------------------------------------------
# One bitcode file per operating system, since the C library's headers differ
# (Darwin's `\01_fputs` and `__maskrune` against glibc's `stdin` and
# `__ctype_b_loc`). Each must exist, carry the ABI stamp, pin nothing to the
# machine that built it, and compile for both architectures of its OS. A
# missing file is a failure, not a skip: this section once passed by grepping
# a file that had been deleted.
printf "\nprebuilt runtimes\n"
LLC="$LLVM_BIN/llc"
for os in darwin linux; do
  bc="$ROOT/catmint-gen/runtime-$os.bc"
  if [ ! -f "$bc" ]; then
    printf "  %-30s ${RED}MISSING${NC}\n" "runtime-$os.bc"
    failed=1
    continue
  fi
  if ! "$LLVM_BIN/llvm-dis" "$bc" -o "$WORK/rt-$os.ll" 2>"$WORK/log"; then
    printf "  %-30s ${RED}UNREADABLE${NC}\n" "runtime-$os.bc"
    sed 's/^/      /' "$WORK/log" | head -3
    failed=1
    continue
  fi
  for pinned in "target triple" "target datalayout" "target-cpu" \
                "target-features" "probe-stack"; do
    if grep -q "$pinned" "$WORK/rt-$os.ll"; then
      printf "  ${RED}runtime-%s.bc is pinned to its machine: %s${NC}\n" "$os" "$pinned"
      failed=1
    fi
  done
  if ! grep -q '@__catmint_abi_[0-9]' "$WORK/rt-$os.ll"; then
    printf "  ${RED}runtime-%s.bc has no ABI stamp${NC}\n" "$os"
    failed=1
  fi
  case $os in
    darwin) triples="arm64-apple-darwin x86_64-apple-darwin" ;;
    linux)  triples="x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu" ;;
  esac
  for target in $triples; do
    if "$LLC" -O2 -filetype=obj -mtriple="$target" "$bc" -o /dev/null \
          2>"$WORK/log"; then
      printf "  %-30s ${GREEN}compiles${NC}\n" "runtime-$os.bc for $target"
    else
      printf "  %-30s ${RED}FAILS${NC}\n" "runtime-$os.bc for $target"
      sed 's/^/      /' "$WORK/log" | head -4
      failed=1
    fi
  done
done

# ---- 2b. the same meaning on both architectures --------------------------
# The file for an OS is built on one architecture (build-runtime.sh explains
# why) and used on both, which is only right if the architectures cannot make
# it mean different things. They did not always agree: before the optimiser
# was taken out, an x86-64 build unrolled loops an aarch64 build did not, and
# plain `char` is unsigned on aarch64 Linux and signed on x86-64, so the
# committed Linux file was reading bytes differently from the macOS one. What
# may still differ is a short list that does not change what a function does:
# alignment hints, the sync/async flavour of `uwtable`, the shape of `jmp_buf`
# (the runtime holds pointers to it and passes them on), and each target's
# default function attributes and module flags (`frame-pointer`,
# `min-legal-vector-width`). The module flags are otherwise compared: the PIC
# and PIE levels must agree.
# Everything else -- every instruction -- must be identical.
printf "\nthe runtime means the same on both architectures\n"
meaning() {
  "$LLVM_BIN/llvm-dis" "$1" -o - | grep -v '^; ModuleID' \
    | grep -v '^%struct.__jmp_buf_tag = ' \
    | sed -E -e 's/!([0-9]+)/!N/g' -e 's/align [0-9]+/align N/g' \
             -e 's/uwtable\(sync\)/uwtable/g' -e 's/\[(37|48) x i32\]/[J x i32]/g' \
             -e 's/ "frame-pointer"="[a-z-]*"//g' -e 's/ "min-legal-vector-width"="0"//g' \
             -e 's/(!"uwtable", i32) [0-9]/\1 N/' \
             -e '/^!N = !\{i32 7, !"frame-pointer", i32 [0-9]\}$/d' \
             -e 's/^(!llvm\.module\.flags) = .*/\1/'
}
same_meaning() {   # label, file A, file B
  meaning "$2" > "$WORK/meaning.a"; meaning "$3" > "$WORK/meaning.b"
  if diff -q "$WORK/meaning.a" "$WORK/meaning.b" >/dev/null; then
    printf "  %-30s ${GREEN}identical${NC}\n" "$1"
  else
    printf "  %-30s ${RED}DIFFERS${NC}\n" "$1"
    diff "$WORK/meaning.a" "$WORK/meaning.b" | grep '^[<>]' | cut -c1-150 | head -6 | sed 's/^/      /'
    failed=1
  fi
}
if [ "$(uname -s)" = Darwin ]; then
  RUNTIME_TARGET=arm64-apple-macos "$ROOT/catmint-gen/build-runtime.sh" --out "$WORK/rt.arm64.bc"
  RUNTIME_TARGET=x86_64-apple-macos "$ROOT/catmint-gen/build-runtime.sh" --out "$WORK/rt.x86.bc"
  same_meaning "darwin arm64 / x86_64" "$WORK/rt.arm64.bc" "$WORK/rt.x86.bc"
  printf "  %-30s not checked here (needs a Linux host of the other architecture)\n" "linux x86_64 / aarch64"
elif [ "$(uname -m)" = x86_64 ]; then
  printf "  %-30s not checked here (the committed file is x86_64; compared on an aarch64 host)\n" "linux x86_64 / aarch64"
else
  "$ROOT/catmint-gen/build-runtime.sh" --out "$WORK/rt.native.bc"
  same_meaning "linux x86_64 / $(uname -m)" "$ROOT/catmint-gen/runtime-linux.bc" "$WORK/rt.native.bc"
fi

# ---- 3. a generated program -----------------------------------------------
printf "\ngenerated program IR\n"
SOURCE=${1:-"$ROOT/catmint-gen/test_suite/08_tour.cm"}
"$ROOT/catmint-lex/bin/catmint-parser" -I "$ROOT/lib" "$SOURCE" \
    "$WORK/p.ast" >/dev/null 2>&1
( cd "$WORK" && "$ROOT/catmint-gen/bin/catmint-gen" p.ast p.sem ) >/dev/null 2>&1
for target in $TARGETS; do
  if "$CLANG" --target="$target" -O2 -Wno-override-module -c \
        "$WORK/p.ast.ll" -o /dev/null 2>"$WORK/log"; then
    printf "  %-30s ${GREEN}compiles${NC}\n" "$target"
  else
    printf "  %-30s ${RED}FAILS${NC}\n" "$target"
    sed 's/^/      /' "$WORK/log" | head -4
    failed=1
  fi
done

echo "------------------------------------------------------------"
if [ "$failed" -ne 0 ]; then
  printf "${RED}not portable${NC}\n"
  exit 1
fi
printf "${GREEN}portable across every target checked${NC}\n"
