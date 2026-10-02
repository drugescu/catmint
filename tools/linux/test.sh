#!/bin/sh
# Build and test catmint on Linux, inside the catmint-linux container:
#
#   tools/linux/run.sh tools/linux/test.sh [--thorough]
#
# Works on a copy of the repository, so that the Linux binaries it builds do
# not overwrite the host's in the mounted tree. After the ordinary suite it
# builds programs the way a user would -- LLVM's tools and lld, with no clang
# anywhere on the path -- and checks the executables keep the hardening the
# compiler driver used to supply.
set -e
# The host's build outputs are left behind rather than copied and deleted:
# they are the wrong platform, and a host build running at the same time
# would change them under the copy.
rm -rf /tmp/cm
mkdir -p /tmp/cm
tar -C /catmint --exclude=./catmint-ast/build --exclude=./catmint-lex/bin \
    --exclude=./catmint-gen/bin --exclude='*.o' --exclude=./.git -cf - . |
  tar -C /tmp/cm -xf -
cd /tmp/cm
(cd catmint-ast && make -f GNUmakefile build LLVM_CONFIG="$LLVM_CONFIG") >/tmp/build.log 2>&1
(cd catmint-lex && make LLVM_CONFIG="$LLVM_CONFIG") >>/tmp/build.log 2>&1
(cd catmint-gen && make LLVM_CONFIG="$LLVM_CONFIG") >>/tmp/build.log 2>&1 || {
  tail -20 /tmp/build.log; exit 1; }
PATH="$LLVM_BIN:$PATH" ./test.sh "$@"

echo
echo "user path: LLVM tools and lld only"
NOCLANG=/tmp/llvm-noclang
mkdir -p "$NOCLANG"
for tool in llvm-link opt llc ld.lld; do ln -sf "$LLVM_BIN/$tool" "$NOCLANG/$tool"; done
env -i HOME=/tmp PATH=/usr/bin:/bin LLVM_BIN="$NOCLANG" \
  ./catmintc examples/wordcount.cm -o /tmp/wc >/dev/null
echo "one two two" > /tmp/words.txt
/tmp/wc /tmp/words.txt | head -3
env -i HOME=/tmp PATH=/usr/bin:/bin LLVM_BIN="$NOCLANG" \
  ./catmintc -g -O0 examples/tour.cm -o /tmp/tour >/dev/null
/tmp/tour | head -1

echo
echo "hardening"
fail=0
readelf -h /tmp/wc | grep -q 'Type:.*DYN' && echo "  position independent" || { echo "  NOT position independent"; fail=1; }
readelf -l /tmp/wc | grep -q GNU_RELRO && echo "  read-only relocations" || { echo "  no RELRO"; fail=1; }
readelf -d /tmp/wc | grep -q 'BIND_NOW\|FLAGS.*NOW' && echo "  bound at load (now)" || { echo "  not bound now"; fail=1; }
readelf -lW /tmp/wc | grep GNU_STACK | grep -q ' RW ' && echo "  stack not executable" || { echo "  executable stack"; fail=1; }
exit $fail
