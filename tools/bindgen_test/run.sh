#!/bin/sh
# Test tools/bindgen.py: bind sample.h, build sample.c into a library, and
# check that a catmint program using the bindings agrees with C about every
# field, and that what cannot be bound is listed with its reason.
#
#   tools/bindgen_test/run.sh
#
# Needs clang, like the tool itself.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || \
                                  echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
export LLVM_BIN
CLANG="$LLVM_BIN/clang"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

"$CLANG" -O1 -c "$HERE/sample.c" -o "$work/sample.o"
ar rcs "$work/libsample.a" "$work/sample.o"
python3 "$ROOT/tools/bindgen.py" "$HERE/sample.h" --match '^[Ss]ample' \
  --constants-match '^SAMPLE_' --from 'bindgen_test/sample\.h$' --class Sample --constants SampleC \
  --link sample --clang "$CLANG" > "$work/sample.cmm"

failed=0
for want in "sample_printf -- is variadic" \
            "sample_origin -- passes a struct by value" \
            "sample_inline -- is inline" \
            "SamplePacked (fields) -- has bitfields"; do
  grep -qF -- "$want" "$work/sample.cmm" || { echo "not listed: $want"; failed=1; }
done
for unwanted in "SAMPLE_NAME" "SAMPLE_POS:" "def Int sample_printf"; do
  if grep -qF -- "$unwanted" "$work/sample.cmm"; then
    echo "bound, and should not be: $unwanted"; failed=1
  fi
done

"$ROOT/catmintc" -I "$work" -L "$work" "$HERE/use.cm" -o "$work/use" > "$work/build.log" 2>&1 || {
  cat "$work/build.log"; echo "--- generated:"; cat "$work/sample.cmm"; exit 1; }
"$work/use" > "$work/out"
if ! diff "$HERE/use.expected" "$work/out"; then
  failed=1
fi
[ "$failed" -eq 0 ] && echo "bindings agree with C" || { echo "--- generated:"; cat "$work/sample.cmm"; exit 1; }
