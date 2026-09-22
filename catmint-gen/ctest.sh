#!/bin/sh
# Code generation test suite.
#
# For every test_suite/*.cm: parse -> semantic analysis -> IR -> link with the
# runtime -> execute, and diff the program's stdout against test_suite/<name>.expected.
#
# A test may supply stdin via test_suite/<name>.stdin.
# Run a single test:  ./ctest.sh test_suite/01_hello.cm
LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
LLVM_LINK="$LLVM_BIN/llvm-link"
LLI="$LLVM_BIN/lli"
PARSER=../catmint-lex/bin/catmint-parser
GEN=./bin/catmint-gen

GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

./build-runtime.sh "$WORK/runtime.host.ll"

tests=0; errors=0; failed=""
for file in ${*:-test_suite/*.cm}; do
  tests=$((tests+1))
  name=$(basename "$file" .cm)
  expected="test_suite/$name.expected"
  printf "%-28s " "$name"

  if [ ! -f "$expected" ]; then
    printf "${RED}NO .expected${NC}\n"; errors=$((errors+1)); failed="$failed $name"; continue
  fi

  # A test with a .separate marker is built the other way: every module is
  # compiled to its own object and the objects are linked. Same source, same
  # expected output, so the two builds are checked against each other.
  if [ -f "test_suite/$name.separate" ]; then
    if ! ../catmintc --separate -I test_suite/modules -I ../lib "$file" -o "$WORK/$name.bin" \
          >"$WORK/$name.sep.log" 2>&1; then
      printf "${RED}FAIL${NC} (separate build; see $WORK/$name.sep.log)\n"
      errors=$((errors+1)); failed="$failed $name"; continue
    fi
    if [ -f "test_suite/$name.stdin" ]; then
      "$WORK/$name.bin" <"test_suite/$name.stdin" >"$WORK/$name.out" 2>&1
    else
      "$WORK/$name.bin" </dev/null >"$WORK/$name.out" 2>&1
    fi
    if diff -q "$WORK/$name.out" "$expected" >/dev/null 2>&1; then
      printf "${GREEN}ok${NC} (separate)\n"
    else
      printf "${RED}FAIL${NC} (separate, output)\n"
      diff "$expected" "$WORK/$name.out" | sed 's/^/      /' | head -20
      errors=$((errors+1)); failed="$failed $name"
    fi
    continue
  fi

  # 1. parse. test_suite/modules holds the .cmm files that tests import.
  if ! $PARSER -I test_suite/modules -I ../lib "$file" "$WORK/$name.ast" >"$WORK/$name.parse.log" 2>&1; then
    printf "${RED}FAIL${NC} (parser)\n"; errors=$((errors+1)); failed="$failed $name"; continue
  fi
  if [ ! -s "$WORK/$name.ast" ]; then
    printf "${RED}FAIL${NC} (parser produced no AST; see $WORK/$name.parse.log)\n"
    errors=$((errors+1)); failed="$failed $name"; continue
  fi

  # 2. semantic analysis + IR generation (writes <ast basename>.ll into CWD)
  if ! (cd "$WORK" && "$OLDPWD/$GEN" "$name.ast" "$name.sem") >"$WORK/$name.gen.log" 2>&1; then
    printf "${RED}FAIL${NC} (codegen; see $WORK/$name.gen.log)\n"
    errors=$((errors+1)); failed="$failed $name"; continue
  fi
  if [ ! -f "$WORK/$name.ast.ll" ]; then
    printf "${RED}FAIL${NC} (no IR emitted; see $WORK/$name.gen.log)\n"
    errors=$((errors+1)); failed="$failed $name"; continue
  fi

  # 3. link + run
  if ! "$LLVM_LINK" "$WORK/$name.ast.ll" "$WORK/runtime.host.ll" -o "$WORK/$name.bc" \
        >"$WORK/$name.link.log" 2>&1; then
    printf "${RED}FAIL${NC} (link; see $WORK/$name.link.log)\n"
    errors=$((errors+1)); failed="$failed $name"; continue
  fi

  if [ -f "test_suite/$name.stdin" ]; then
    "$LLI" "$WORK/$name.bc" <"test_suite/$name.stdin" >"$WORK/$name.out" 2>"$WORK/$name.err"
  else
    "$LLI" "$WORK/$name.bc" </dev/null >"$WORK/$name.out" 2>"$WORK/$name.err"
  fi
  rc=$?

  if [ $rc -ne 0 ]; then
    printf "${RED}FAIL${NC} (exit $rc)\n"
    sed 's/^/      | /' "$WORK/$name.err" | head -5
    errors=$((errors+1)); failed="$failed $name"; continue
  fi

  if diff -q "$WORK/$name.out" "$expected" >/dev/null 2>&1; then
    printf "${GREEN}ok${NC}\n"
  else
    printf "${RED}FAIL${NC} (output)\n"
    diff "$expected" "$WORK/$name.out" | sed 's/^/      /' | head -20
    errors=$((errors+1)); failed="$failed $name"
  fi
done

echo "------------------------------------------------------------"
if [ $errors -ne 0 ]; then
  printf "${RED}%d/%d failed:${NC}%s\n" "$errors" "$tests" "$failed"
  exit 1
else
  printf "${GREEN}all %d passed${NC}\n" "$tests"
fi
