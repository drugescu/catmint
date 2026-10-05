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
python3 "$ROOT/tools/bindgen.py" "$HERE/sample.h" --match '^([Ss]ample|atexit$)' \
  --constants-match '^SAMPLE_' --constants-match '^OTHER_' \
  --string-returns '^sample_name$' --foreign-thread '^SampleTick$' \
  --from 'bindgen_test/sample\.h$' --class Sample --constants SampleC \
  --link sample --clang "$CLANG" > "$work/sample.cmm"

failed=0
for want in "sample_printf -- is variadic" \
            "sample_origin -- passes a struct by value" \
            "sample_inline -- is inline" \
            "SamplePacked (fields) -- has bitfields" \
            "sample_log -- is variadic and takes a format string" \
            "constants pattern ^OTHER_ matched 1 names" \
            "def String sample_name(Int id)" \
            "def Ptr sample_dup(String s)" \
            "  Int64 a @ 0" \
            "extern def SampleVisit(Ptr arg0, Int arg1) Int" \
            "extern def sample_largest_better(Int64 arg0, Int64 arg1) Int" \
            "def Void sample_each(Int n, SampleVisit fn, Ptr userdata)" \
            "def Int sample_largest(Ptr values, Int count, sample_largest_better better)" \
            "SampleSpoiled (callback type) -- passes a struct by value" \
            "def Void sample_spoiled(Ptr handler)" \
            "atexit -- installs a handler" \
            "SampleTick (callback type) -- the library calls it from threads of its own" \
            "def Void sample_every(Ptr fn, Ptr userdata)"; do
  grep -qF -- "$want" "$work/sample.cmm" || { echo "not listed: $want"; failed=1; }
done
for unwanted in "SAMPLE_NAME" "SAMPLE_POS:" "def Int sample_printf" "def Int atexit" \
                "extern def SampleTick"; do
  if grep -qF -- "$unwanted" "$work/sample.cmm"; then
    echo "bound, and should not be: $unwanted"; failed=1
  fi
done

# The same header bound for Windows, which this machine is not: `long` is four
# bytes there, so it must come out as Int and unsigned long as UInt32 where
# here they are Int64 and UInt64, and clang's own layout for that target is what
# the offsets assert (b at 4, not 8). -ffreestanding keeps clang's own stdint.h,
# since the host's headers describe the host.
python3 "$ROOT/tools/bindgen.py" "$HERE/sample.h" --match '^[Ss]ample' \
  --from 'bindgen_test/sample\.h$' --class Sample --clang "$CLANG" \
  --target x86_64-pc-windows-msvc --clang-arg=-ffreestanding > "$work/sample_win.cmm"
for want in "  Int a @ 0" "  UInt32 b @ 4" "  Int64 c @ 8"; do
  grep -qF -- "$want" "$work/sample_win.cmm" || { echo "for Windows, not bound as: $want"; failed=1; }
done

# A constants pattern that matches nothing is said out loud, not left to look
# like an empty header.
python3 "$ROOT/tools/bindgen.py" "$HERE/sample.h" --match '^[Ss]ample' \
  --constants-match '^NOTHING_LIKE_THIS_' --from 'bindgen_test/sample\.h$' \
  --class Sample --constants SampleC --clang "$CLANG" > "$work/none.cmm" 2> "$work/none.err"
grep -qF "matched nothing" "$work/none.err" || { echo "an empty pattern was not reported"; failed=1; }

"$ROOT/catmintc" -I "$work" -L "$work" "$HERE/use.cm" -o "$work/use" > "$work/build.log" 2>&1 || {
  cat "$work/build.log"; echo "--- generated:"; cat "$work/sample.cmm"; exit 1; }
"$work/use" > "$work/out"
if ! diff "$HERE/use.expected" "$work/out"; then
  failed=1
fi
[ "$failed" -eq 0 ] && echo "bindings agree with C" || { echo "--- generated:"; cat "$work/sample.cmm"; exit 1; }
