#!/bin/sh
# Compile and run every code generation test under AddressSanitizer, and on
# Linux under LeakSanitizer with it, since that is the only place it runs.
#
#   ./sanitize.sh
#
# This is the check to repeat after anything touching reference counting: a
# release too many is a use-after-free here and nothing at all otherwise, and
# a release too few is a leak that only Linux reports.
#
# It lives here rather than inline in the CI workflow because that is how it
# went wrong once: the loop existed only in YAML, could not be run locally,
# and had two faults nobody could see. It ran from the repository root, so a
# test's `.args` -- which ctest.sh reads relative to catmint-gen -- did not
# resolve and 33_wordcount exited early without doing any work. And it
# captured a program's output without `|| true`, so under `bash -e` the first
# test that exited non-zero killed the whole step before anything could be
# reported: the failure was an exit code with no output at all.
#
# One environment it cannot run in: qemu-user emulation. AddressSanitizer's
# allocator fails a CHECK in sanitizer_allocator_primary32.h there, on every
# program including one that only prints a string, so an emulated x86-64
# container reports all of them and means none of it. Verify x86-64 on a real
# x86-64 machine -- CI does.
set -e

ROOT=$(cd "$(dirname "$0")" && pwd)
LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || \
                                  echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
export LLVM_BIN
GREEN='\033[1;32m'; RED='\033[1;31m'; NC='\033[0m'

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# From catmint-gen, because that is where ctest.sh runs and what a test's
# `.args` and `.stdin` paths are written against.
cd "$ROOT/catmint-gen"

findings=0
checked=0
unbuilt=""

for source in test_suite/*.cm; do
  name=$(basename "$source" .cm)

  if ! ../catmintc --asan -I ../lib -I test_suite/modules "$source" \
        -o "$WORK/$name" >"$WORK/$name.build" 2>&1; then
    unbuilt="$unbuilt $name"
    continue
  fi

  args=""
  if [ -f "test_suite/$name.args" ]; then
    args=$(cat "test_suite/$name.args")
  fi

  # `|| true` on both: a test may exit non-zero on purpose -- 33_wordcount
  # does when it has no file to read -- and a sanitizer finding always does.
  # Either way the output is what matters, and letting the status through
  # would end the run here.
  # shellcheck disable=SC2086
  if [ -f "test_suite/$name.stdin" ]; then
    out=$("$WORK/$name" $args <"test_suite/$name.stdin" 2>&1) || true
  else
    out=$("$WORK/$name" $args </dev/null 2>&1) || true
  fi

  checked=$((checked + 1))
  if printf '%s' "$out" | grep -q "Sanitizer"; then
    printf "${RED}%s${NC}\n" "$name"
    printf '%s\n' "$out" | grep -A5 -E "ERROR: (Address|Leak)Sanitizer|LeakSanitizer:" \
      | head -14 | sed 's/^/    /'
    findings=$((findings + 1))
  fi
done

echo "------------------------------------------------------------"
[ -n "$unbuilt" ] && echo "did not build under --asan:$unbuilt"
if [ "$findings" -ne 0 ]; then
  printf "${RED}%d of %d tests reported a sanitizer finding${NC}\n" \
    "$findings" "$checked"
  exit 1
fi
printf "${GREEN}%d tests clean under the sanitizers${NC}\n" "$checked"
