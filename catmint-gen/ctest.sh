#!/bin/sh
# Code generation test suite.
#
# For every test_suite/*.cm: parse -> semantic analysis -> IR -> link with the
# runtime -> execute, and diff the program's stdout against test_suite/<name>.expected.
#
# A test may supply stdin via test_suite/<name>.stdin, and command-line
# arguments via test_suite/<name>.args (one line, whitespace separated).
#
# A test may also supply test_suite/<name>.check, an executable script run
# with the source file as its argument once the output has matched. It is for
# things the program's own output cannot show -- what is in the generated IR,
# say. A non-zero exit fails the test.
# Run a single test:  ./ctest.sh test_suite/01_hello.cm
#
# --thorough additionally compiles every test to a native binary at -O0, -O1,
# -O2 and -O3 and requires the same output from all four, and tries the
# separately compiled build as well. The everyday run does none of that: it
# JITs one build with lli, which is fast but sees only one set of optimiser
# decisions. Bugs that appear at one -O level and not another are a real
# class here -- a function containing a `try` needs its locals volatile, and
# without that it is correct at -O0 and wrong at -O2.
THOROUGH=0
WANTED=""
for arg in "$@"; do
  case "$arg" in
    --thorough) THOROUGH=1 ;;
    *) WANTED="$WANTED $arg" ;;
  esac
done

LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
LLVM_LINK="$LLVM_BIN/llvm-link"
LLI="$LLVM_BIN/lli"
PARSER=../catmint-lex/bin/catmint-parser
GEN=./bin/catmint-gen

GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

./build-runtime.sh "$WORK/runtime.host.ll"

# run_binary <binary> <output file> -- with this test's stdin and arguments.
# Standard error goes to its own file, not into the output being compared:
# 30_args writes a usage line there on purpose, and folding the two together
# made the sweep disagree with the run it was supposed to be checking.
run_binary() {
  # shellcheck disable=SC2086
  if [ -f "test_suite/$name.stdin" ]; then
    "$1" $PROGRAM_ARGS <"test_suite/$name.stdin" >"$2" 2>"$2.err"
  else
    "$1" $PROGRAM_ARGS </dev/null >"$2" 2>"$2.err"
  fi
}

# sweep -- compile this test to a native binary at every optimisation level and
# require identical output from all of them, then try the separately compiled
# build. Only --thorough runs it. Sets sweep_note for the success line.
sweep() {
  sweep_note=""
  for opt in -O0 -O1 -O2 -O3; do
    if ! ../catmintc $opt -I test_suite/modules -I ../lib "$file" \
          -o "$WORK/$name$opt.bin" >"$WORK/$name$opt.log" 2>&1; then
      printf "${RED}FAIL${NC} ($opt build; see $WORK/$name$opt.log)\n"
      return 1
    fi
    run_binary "$WORK/$name$opt.bin" "$WORK/$name$opt.out"
    if ! diff -q "$WORK/$name$opt.out" "$expected" >/dev/null 2>&1; then
      printf "${RED}FAIL${NC} (output at $opt)\n"
      diff "$expected" "$WORK/$name$opt.out" | sed 's/^/      /' | head -20
      return 1
    fi
  done
  sweep_note=" -O0..3"

  # The separately compiled build too, where the program can be built that
  # way. A build failure here is not a test failure: `using namespace` has no
  # meaning under --separate and several tests use it. Wrong output is.
  if ../catmintc --separate -I test_suite/modules -I ../lib "$file" \
        -o "$WORK/$name.sep.bin" >"$WORK/$name.sep.log" 2>&1; then
    run_binary "$WORK/$name.sep.bin" "$WORK/$name.sep.out"
    if ! diff -q "$WORK/$name.sep.out" "$expected" >/dev/null 2>&1; then
      printf "${RED}FAIL${NC} (output when separately compiled)\n"
      diff "$expected" "$WORK/$name.sep.out" | sed 's/^/      /' | head -20
      return 1
    fi
    sweep_note="$sweep_note +sep"
  fi
  return 0
}

tests=0; errors=0; failed=""
for file in ${WANTED:-test_suite/*.cm}; do
  tests=$((tests+1))
  name=$(basename "$file" .cm)
  expected="test_suite/$name.expected"
  sweep_note=""
  printf "%-28s " "$name"

  # Command-line arguments for the program under test, if it wants any.
  if [ -f "test_suite/$name.args" ]; then
    set -f
    # shellcheck disable=SC2046
    PROGRAM_ARGS=$(cat "test_suite/$name.args")
    set +f
  else
    PROGRAM_ARGS=""
  fi

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
    # shellcheck disable=SC2086
    if [ -f "test_suite/$name.stdin" ]; then
      "$WORK/$name.bin" $PROGRAM_ARGS <"test_suite/$name.stdin" >"$WORK/$name.out" 2>&1
    else
      "$WORK/$name.bin" $PROGRAM_ARGS </dev/null >"$WORK/$name.out" 2>&1
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

  # shellcheck disable=SC2086
  if [ -f "test_suite/$name.stdin" ]; then
    "$LLI" "$WORK/$name.bc" $PROGRAM_ARGS <"test_suite/$name.stdin" >"$WORK/$name.out" 2>"$WORK/$name.err"
  else
    "$LLI" "$WORK/$name.bc" $PROGRAM_ARGS </dev/null >"$WORK/$name.out" 2>"$WORK/$name.err"
  fi
  rc=$?

  if [ $rc -ne 0 ]; then
    printf "${RED}FAIL${NC} (exit $rc)\n"
    sed 's/^/      | /' "$WORK/$name.err" | head -5
    errors=$((errors+1)); failed="$failed $name"; continue
  fi

  if ! diff -q "$WORK/$name.out" "$expected" >/dev/null 2>&1; then
    printf "${RED}FAIL${NC} (output)\n"
    diff "$expected" "$WORK/$name.out" | sed 's/^/      /' | head -20
    errors=$((errors+1)); failed="$failed $name"
    continue
  fi

  if [ "$THOROUGH" -eq 1 ] && ! sweep; then
    errors=$((errors+1)); failed="$failed $name"
    continue
  fi

  if [ -x "test_suite/$name.check" ]; then
    if ! "test_suite/$name.check" "$file" >"$WORK/$name.check.log" 2>&1; then
      printf "${RED}FAIL${NC} (check)\n"
      sed 's/^/      /' "$WORK/$name.check.log" | head -10
      errors=$((errors+1)); failed="$failed $name"
      continue
    fi
    printf "${GREEN}ok${NC} (checked)$sweep_note\n"
    continue
  fi

  printf "${GREEN}ok${NC}$sweep_note\n"
done

echo "------------------------------------------------------------"
if [ $errors -ne 0 ]; then
  printf "${RED}%d/%d failed:${NC}%s\n" "$errors" "$tests" "$failed"
  exit 1
else
  printf "${GREEN}all %d passed${NC}\n" "$tests"
fi
