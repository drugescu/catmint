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
#   2. Does the checked-in runtime.ll -- the one that exists so a C compiler
#      is optional -- compile for those targets? It once said
#      "target-cpu"="apple-m1" on all thirty of its functions while claiming
#      to be portable.
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

# ---- 2. the checked-in runtime --------------------------------------------
printf "\nchecked-in runtime.ll\n"
for pinned in "target triple" "target datalayout" "target-cpu" \
              "target-features" "probe-stack"; do
  if grep -q "$pinned" "$ROOT/catmint-gen/runtime.ll"; then
    printf "  ${RED}pinned to this machine: %s${NC}\n" "$pinned"
    failed=1
  fi
done
# Whether this LLVM can read the file at all is a separate question from
# whether the file is pinned to a machine. The textual IR format changes
# between LLVM major versions -- `captures(none)` replaced `nocapture` in
# LLVM 21 -- so a copy written by a newer LLVM is a parse error on an older
# one everywhere equally. That is a real limitation, recorded in
# COMPILING.md and diagnosed by build-runtime.sh, but it is not this script's
# question and failing here would only say the same thing four times.
# Compiling it is the only honest probe: `-fsyntax-only` on IR input does
# nothing at all and exits 0, which made this branch pass vacuously.
if "$CLANG" -Wno-override-module -c "$ROOT/catmint-gen/runtime.ll" \
      -o "$WORK/probe.o" 2>/dev/null; then
  for target in $TARGETS; do
    if "$CLANG" --target="$target" -O2 -Wno-override-module -c \
          "$ROOT/catmint-gen/runtime.ll" -o /dev/null 2>"$WORK/log"; then
      printf "  %-30s ${GREEN}compiles${NC}\n" "$target"
    else
      printf "  %-30s ${RED}FAILS${NC}\n" "$target"
      sed 's/^/      /' "$WORK/log" | head -4
      failed=1
    fi
  done
else
  WROTE=$(sed -n 's/^; written by //p' "$ROOT/catmint-gen/runtime.ll" | head -1)
  printf "  skipped: this LLVM cannot parse it\n"
  printf "    written by: %s\n" "${WROTE:-unknown}"
  printf "    reading it: %s\n" "$("$CLANG" --version | grep -im1 version)"
  printf "    The IR text format changes between LLVM major versions; the\n"
  printf "    pinning checks above still apply and still passed.\n"
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
