#!/bin/sh
# Differential testing against C.
#
#   ./difftest/run.sh [count] [first-seed]
#
# For each seed: generate the same program in catmint and in C, compile both,
# run both, and require identical output. catmint is built at -O0 and at -O2,
# so a disagreement between those two is caught in the same pass -- that is
# the cheapest place to see an optimiser-dependent bug.
#
# A failing seed is reproducible on its own:
#   python3 difftest/generate.py 4711 /tmp/a.cm /tmp/a.c
# and the sources of every failure are left in difftest/failures/.
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
COUNT=${1:-200}
FIRST=${2:-1}

LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || \
                                  echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
export LLVM_BIN
CLANG="$LLVM_BIN/clang"

GREEN='\033[1;32m'; RED='\033[1;31m'; NC='\033[0m'

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
FAILDIR="$ROOT/difftest/failures"

fail_count=0
seed=$FIRST
last=$((FIRST + COUNT - 1))

while [ "$seed" -le "$last" ]; do
  cm="$WORK/p.cm"; csrc="$WORK/p.c"
  python3 "$ROOT/difftest/generate.py" "$seed" "$cm" "$csrc"

  keep() {
    mkdir -p "$FAILDIR"
    cp "$cm" "$FAILDIR/seed$seed.cm"
    cp "$csrc" "$FAILDIR/seed$seed.c"
    printf "${RED}seed %s: %s${NC}\n" "$seed" "$1"
    fail_count=$((fail_count + 1))
  }

  if ! "$CLANG" -O2 -w "$csrc" -o "$WORK/p.cbin" >"$WORK/c.log" 2>&1; then
    keep "C did not compile"; seed=$((seed + 1)); continue
  fi
  "$WORK/p.cbin" > "$WORK/c.out" 2>&1 || true

  ok=1
  for opt in -O0 -O2; do
    if ! "$ROOT/catmintc" "$opt" "$cm" -o "$WORK/p.cmbin$opt" \
          >"$WORK/cm$opt.log" 2>&1; then
      keep "catmint did not compile at $opt"; ok=0; break
    fi
    "$WORK/p.cmbin$opt" > "$WORK/cm$opt.out" 2>&1 || true
    if ! diff -q "$WORK/cm$opt.out" "$WORK/c.out" >/dev/null 2>&1; then
      keep "output differs from C at $opt"
      diff "$WORK/c.out" "$WORK/cm$opt.out" | head -10 | sed 's/^/      /'
      ok=0; break
    fi
  done

  [ "$ok" -eq 1 ] && printf "."
  seed=$((seed + 1))
done

printf "\n------------------------------------------------------------\n"
if [ "$fail_count" -ne 0 ]; then
  printf "${RED}%d of %d seeds disagreed; sources in difftest/failures/${NC}\n" \
    "$fail_count" "$COUNT"
  exit 1
fi
printf "${GREEN}%d seeds agreed with C${NC}\n" "$COUNT"
