#!/bin/sh
# Callbacks from a C library: the widths, a struct, userdata through a handle,
# an error, and a call from a thread C made. Needs clang to build the C
# library, like the binding generator's test, and says so when it is missing.
#
#   tools/callback_test/run.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || \
                                  echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
export LLVM_BIN
CLANG="$LLVM_BIN/clang"
if [ ! -x "$CLANG" ] && ! command -v clang >/dev/null 2>&1; then
  echo "skipped: needs clang"
  exit 0
fi
[ -x "$CLANG" ] || CLANG=clang
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failed=0

"$CLANG" -O1 -c "$HERE/cb.c" -o "$work/cb.o"
ar rcs "$work/libcb.a" "$work/cb.o"

"$ROOT/catmintc" -L "$work" "$HERE/use.cm" -o "$work/use" > "$work/use.log" 2>&1 || {
  cat "$work/use.log"; exit 1; }
"$work/use" > "$work/use.out" 2>&1 || true
diff "$HERE/use.expected" "$work/use.out" || failed=1

"$ROOT/catmintc" -L "$work" "$HERE/thread.cm" -o "$work/thread" > "$work/thread.log" 2>&1 || {
  cat "$work/thread.log"; exit 1; }
# The abort is the expected result; the braces keep the shell from announcing it.
if { "$work/thread" > "$work/thread.out" 2> "$work/thread.err"; } 2>/dev/null; then
  echo "a callback ran on a C thread, and it should have been refused"; failed=1
elif ! grep -q "calling from a C thread" "$work/thread.out" ||
     grep -q "not reached" "$work/thread.out"; then
  echo "the thread test did not stop where it should:"; cat "$work/thread.out"; failed=1
elif ! grep -q "thread other than the program's main thread" "$work/thread.err"; then
  echo "refused, but not saying why:"; cat "$work/thread.err"; failed=1
fi

[ "$failed" -eq 0 ] && echo "callbacks agree with C, and a foreign thread is refused" || exit 1
