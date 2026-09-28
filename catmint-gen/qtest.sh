#!/bin/sh
# End-to-end smoke test: .cm source -> parser -> AST -> semantic analysis ->
# LLVM IR -> linked with the runtime -> executed.
#
# LLVM tools are found on PATH; override with LLVM_BIN=/path/to/llvm/bin.
set -e

LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
LLVM_LINK="$LLVM_BIN/llvm-link"
LLI="$LLVM_BIN/lli"

file1=${1:-test/class_test.cm}
base=$(basename "$file1")

echo "Parsing file $file1..."
../catmint-lex/bin/catmint-parser "$file1" "$file1.ast"

echo
echo "Semantic verification and code generation on $file1.ast"
./bin/catmint-gen "$file1.ast" "$file1.sem"

# catmint-gen writes <basename of input>.ll into the current directory.
ir="$base.ast.ll"
bc="$base.bc"

# The committed runtime.ll is x86_64 Linux; derive a host-portable copy.
./build-runtime.sh runtime.host.ll

echo
echo "Linking $ir with the runtime..."
"$LLVM_LINK" "$ir" runtime.host.ll -o "$bc"

echo "Running $bc:"
echo "----------------------------------------"
"$LLI" "$bc"
echo "----------------------------------------"
echo "Done."
