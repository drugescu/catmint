#!/bin/sh
# Build everything and run every test in the repository.
#
#   ./test.sh             build, then run both suites
#   ./test.sh --no-build  run the suites against what is already built
#   ./test.sh --thorough  also compile every codegen test at -O0..-O3 and
#                         separately, and require the same output from each
#
# The parser suite diffs each test_suite/*.cm against its committed .ref;
# the code generation suite compiles and runs every catmint-gen/test_suite/*.cm
# and diffs its output against the matching .expected. Exits non-zero if
# anything fails, so it is usable from a hook or a CI job.
set -e

ROOT=$(cd "$(dirname "$0")" && pwd)
GREEN='\033[1;32m'; RED='\033[1;31m'; BOLD='\033[1m'; NC='\033[0m'

BUILD=1
THOROUGH=""
for arg in "$@"; do
  case "$arg" in
    --no-build) BUILD=0 ;;
    --thorough) THOROUGH="--thorough" ;;
    *) echo "test.sh: unknown option $arg" >&2; exit 2 ;;
  esac
done

# Homebrew's LLVM and bison are keg-only, so put them first if they are there.
for dir in /opt/homebrew/opt/llvm@22/bin /opt/homebrew/opt/bison/bin; do
  [ -d "$dir" ] && PATH="$dir:$PATH"
done
export PATH

if [ "$BUILD" -eq 1 ]; then
  printf "${BOLD}building${NC}\n"
  ( cd "$ROOT/catmint-ast" && make -f GNUmakefile build ) >"$ROOT/.build.log" 2>&1
  ( cd "$ROOT/catmint-lex" && make ) >>"$ROOT/.build.log" 2>&1
  ( cd "$ROOT/catmint-gen" && make ) >>"$ROOT/.build.log" 2>&1
  echo "  ok"
fi

failed=0

printf "\n${BOLD}parser${NC}\n"
if ( cd "$ROOT/catmint-lex" && ./wtest.sh ) > "$ROOT/.wtest.log" 2>&1; then
  grep -o "All [0-9]* tests passed" "$ROOT/.wtest.log" | tail -1 | sed 's/^/  /'
else
  printf "  ${RED}failed${NC} - see .wtest.log\n"
  grep -i "ERROR" "$ROOT/.wtest.log" | head -5 | sed 's/^/  /'
  failed=1
fi

printf "\n${BOLD}code generation${NC}\n"
if ( cd "$ROOT/catmint-gen" && ./ctest.sh $THOROUGH ) > "$ROOT/.ctest.log" 2>&1; then
  grep -o "all [0-9]* passed" "$ROOT/.ctest.log" | tail -1 | sed 's/^/  /'
else
  printf "  ${RED}failed${NC}\n"
  grep -A3 "FAIL" "$ROOT/.ctest.log" | head -20 | sed 's/^/  /'
  failed=1
fi

if [ -n "$THOROUGH" ]; then
  printf "\n${BOLD}differential against C${NC}\n"
  if ( cd "$ROOT" && ./difftest/run.sh 50 1 ) > "$ROOT/.difftest.log" 2>&1; then
    grep -o "[0-9]* seeds agreed with C" "$ROOT/.difftest.log" | sed 's/^/  /'
  else
    printf "  ${RED}disagreed${NC} - see .difftest.log and difftest/failures/\n"
    failed=1
  fi
fi

if [ -n "$THOROUGH" ]; then
  printf "\n${BOLD}fuzzing the front end${NC}\n"
  if ( cd "$ROOT" && python3 fuzz/fuzz.py --runs 300 ) > "$ROOT/.fuzz.log" 2>&1; then
    grep -o "[0-9]* mutants.*findings" "$ROOT/.fuzz.log" | sed 's/^/  /'
  else
    printf "  ${RED}crashed${NC} - see .fuzz.log and fuzz/failures/\n"
    failed=1
  fi
fi

printf "\n${BOLD}examples${NC}\n"
for source in "$ROOT"/examples/*.cm; do
  name=$(basename "$source" .cm)
  if "$ROOT/catmintc" -I "$ROOT/lib" "$source" -o "/tmp/catmint-example-$name" >/dev/null 2>&1; then
    printf "  %-12s ${GREEN}builds${NC}\n" "$name"
  else
    printf "  %-12s ${RED}does not build${NC}\n" "$name"
    failed=1
  fi
done

echo "------------------------------------------------------------"
if [ "$failed" -ne 0 ]; then
  printf "${RED}something failed${NC}\n"
  exit 1
fi
printf "${GREEN}everything passed${NC}\n"
