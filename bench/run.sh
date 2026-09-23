#!/bin/sh
# Build and time every benchmark in catmint, C and C++, and check that the
# three agree on the answer before reporting how long each took.
#
#   ./run.sh            all of them
#   ./run.sh fib loop   just those
#
# Times are the best of five runs, which is the fairest thing to report for
# a program this short: the best run is the one least disturbed by whatever
# else the machine was doing.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for dir in /opt/homebrew/opt/llvm@22/bin; do
  [ -d "$dir" ] && PATH="$dir:$PATH"
done
export PATH

CC=${CC:-clang}
CXX=${CXX:-clang++}
OPT=${OPT:--O2}

BENCHES=${*:-fib loop primes strings sieve}

printf "%-10s %12s %12s %12s   %s\n" "benchmark" "catmint" "C $OPT" "C++ $OPT" "answer"
printf "%-10s %12s %12s %12s   %s\n" "---------" "-------" "------" "--------" "------"

for name in $BENCHES; do
  "$ROOT/catmintc" "$HERE/$name.cm" -o "$WORK/$name.cm.bin" >/dev/null
  $CC  $OPT "$HERE/$name.c"   -o "$WORK/$name.c.bin"
  $CXX $OPT "$HERE/$name.cpp" -o "$WORK/$name.cpp.bin"

  # The catmint version of `strings` prints an extra line about live objects,
  # so only the first line is compared.
  answer=$("$WORK/$name.cm.bin" | head -1)
  for other in c cpp; do
    if [ "$("$WORK/$name.$other.bin" | head -1)" != "$answer" ]; then
      echo "$name: the $other version disagrees; not timing it"
      exit 1
    fi
  done

  set -- ""
  for kind in cm c cpp; do
    best=$(python3 - "$WORK/$name.$kind.bin" <<'PY'
import subprocess, sys, time
best = 1e9
for _ in range(5):
    start = time.perf_counter()
    subprocess.run([sys.argv[1]], stdout=subprocess.DEVNULL)
    best = min(best, time.perf_counter() - start)
print("%.3f" % best)
PY
)
    set -- "$@" "$best"
  done
  shift
  printf "%-10s %11ss %11ss %11ss   %s\n" "$name" "$1" "$2" "$3" "$answer"
done
