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
# Passing means the suite said so, not only that it exited 0: wtest.sh once
# exited 0 with a test failing, and this section printed nothing at all.
if ( cd "$ROOT/catmint-lex" && ./wtest.sh ) > "$ROOT/.wtest.log" 2>&1 &&
   grep -q "All [0-9]* tests passed" "$ROOT/.wtest.log"; then
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

# The standard library is found without -I: a program that says `using files`, compiled
# from some other folder, builds, in the usual way and separately compiled.
printf "\n${BOLD}the library needs no flag${NC}\n"
libdir=$(mktemp -d)
printf 'using files\nclass Main from IO\n  def main:\n    out(Files.baseName("a/b.txt"))\n  end\nend\n' > "$libdir/t.cm"
if ( cd "$libdir" && "$ROOT/catmintc" t.cm -o t >/dev/null 2>&1 && [ "$(./t)" = "b.txt" ] &&
     "$ROOT/catmintc" --separate t.cm -o t2 >/dev/null 2>&1 && [ "$(./t2)" = "b.txt" ] ); then
  printf "  a program finds lib/ beside catmintc, from any folder\n"
else
  printf "  ${RED}failed${NC}: catmintc did not find the standard library by itself\n"
  failed=1
fi
rm -rf "$libdir"

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

if [ -n "$THOROUGH" ]; then
  printf "\n${BOLD}portability${NC}\n"
  if ( cd "$ROOT" && ./portability.sh ) > "$ROOT/.portability.log" 2>&1; then
    grep -o "portable across every target checked" "$ROOT/.portability.log" | sed 's/^/  /'
  else
    printf "  ${RED}not portable${NC} - see .portability.log\n"
    failed=1
  fi
fi

# The binding generator is a developer's tool and needs clang, as it does;
# without clang this says so rather than printing nothing.
printf "\n${BOLD}binding generator${NC}\n"
if [ ! -x "${LLVM_BIN:-/nonexistent}/clang" ] && ! command -v clang >/dev/null 2>&1; then
  printf "  skipped: needs clang\n"
elif "$ROOT/tools/bindgen_test/run.sh" > "$ROOT/.bindgen.log" 2>&1; then
  printf "  bindings agree with C\n"
else
  printf "  ${RED}failed${NC} - see .bindgen.log\n"
  tail -5 "$ROOT/.bindgen.log" | sed 's/^/  /'
  failed=1
fi

# A file generated from the lexer must not drift from it: regenerate in memory
# and compare. The editor colours exactly the words the lexer treats as keywords.
printf "\n${BOLD}generated files${NC}\n"
if ! command -v python3 >/dev/null 2>&1; then
  printf "  skipped: needs python3\n"
elif keywords_out=$(python3 "$ROOT/tools/make_keywords.py" --check 2>&1); then
  printf "  %s\n" "$keywords_out"
else
  printf "  ${RED}failed${NC}\n"
  printf "%s\n" "$keywords_out" | sed 's/^/  /'
  failed=1
fi
if command -v python3 >/dev/null 2>&1; then
  if themes_out=$(python3 "$ROOT/tools/make_themes.py" --check 2>&1); then
    printf "  %s\n" "$themes_out"
  else
    printf "  ${RED}failed${NC}\n"
    printf "%s\n" "$themes_out" | sed 's/^/  /'
    failed=1
  fi
  # VS Code's grammar is generated from the lexer too, and checked against a sample.
  if vscode_out=$(python3 "$ROOT/tools/make_vscode.py" --check 2>&1 && python3 "$ROOT/tools/vscode_test.py" 2>&1); then
    printf "  %s\n" "$vscode_out"
  else
    printf "  ${RED}failed${NC}\n"
    printf "%s\n" "$vscode_out" | sed 's/^/  /'
    failed=1
  fi
fi

# Callbacks from a C library: every width of argument, a struct, userdata
# through a handle, an error, and a call from a thread C made, which must be
# refused. The C library is built by clang, so without clang this says so.
printf "\n${BOLD}callbacks${NC}\n"
if [ ! -x "${LLVM_BIN:-/nonexistent}/clang" ] && ! command -v clang >/dev/null 2>&1; then
  printf "  skipped: needs clang\n"
elif "$ROOT/tools/callback_test/run.sh" > "$ROOT/.callbacks.log" 2>&1; then
  printf "  %s\n" "$(tail -1 "$ROOT/.callbacks.log")"
else
  printf "  ${RED}failed${NC} - see .callbacks.log\n"
  tail -6 "$ROOT/.callbacks.log" | sed 's/^/  /'
  failed=1
fi

# SDL, headless: the video, renderer and audio drivers that need no screen or
# sound card. The library's own test runs always; the game's two suites (its
# simulation against an independent port, and scripted input with pixel
# checks) and the editor's (scripted input with state and pixel checks, and a
# measure of the CPU an idle one uses) run with --thorough. Without SDL2
# installed this says so.
printf "\n${BOLD}SDL, the game and the editor${NC}\n"
if sdl_out=$("$ROOT/tools/sdl_test/run.sh" 2>&1); then
  printf "  %s\n" "$sdl_out"
  case "$sdl_out" in
    skipped*) ;;
    *)
      if [ -z "$THOROUGH" ]; then
        printf "  game and editor: skipped (./test.sh --thorough runs them)\n"
      else
        if ( cd "$ROOT/examples/rps-rts" &&
             export SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIODRIVER=dummy &&
             ./build.sh && ./check.sh && ./play.sh ) > "$ROOT/.game.log" 2>&1; then
          printf "  %s\n" "$(grep 'simulation matches' "$ROOT/.game.log")"
          printf "  %s\n" "$(grep 'play tests passed' "$ROOT/.game.log")"
        else
          printf "  ${RED}game failed${NC} - see .game.log\n"
          tail -6 "$ROOT/.game.log" | sed 's/^/  /'
          failed=1
        fi
        if ( cd "$ROOT/examples/pad" &&
             export SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIODRIVER=dummy &&
             ./build.sh && ./play.sh && python3 idle.py ) > "$ROOT/.pad.log" 2>&1; then
          printf "  %s\n" "$(grep 'play tests passed' "$ROOT/.pad.log")"
          printf "  %s\n" "$(grep 'idle pad' "$ROOT/.pad.log")"
        else
          printf "  ${RED}editor failed${NC} - see .pad.log\n"
          tail -6 "$ROOT/.pad.log" | sed 's/^/  /'
          failed=1
        fi
      fi
      ;;
  esac
else
  printf "  ${RED}failed${NC}\n"
  printf "%s\n" "$sdl_out" | tail -5 | sed 's/^/  /'
  failed=1
fi

printf "\n${BOLD}examples${NC}\n"
for source in "$ROOT"/examples/*.cm; do
  name=$(basename "$source" .cm)
  if "$ROOT/catmintc" "$source" -o "/tmp/catmint-example-$name" >/dev/null 2>&1; then
    printf "  %-12s ${GREEN}builds${NC}\n" "$name"
  else
    printf "  %-12s ${RED}does not build${NC}\n" "$name"
    failed=1
  fi
done

# On GitHub the job log cannot be read without signing in, but an annotation can, by anyone: so
# a failure also writes, for each log that has one, the lines that say what failed.
annotate_failures() {
  [ -n "$GITHUB_ACTIONS" ] || return 0
  for log in "$ROOT"/.*.log; do
    [ -f "$log" ] || continue
    clean=$(sed 's/\x1b\[[0-9;]*m//g' "$log")
    # Every test that failed, one line each, then the first one's whole report.
    names=$(printf '%s\n' "$clean" | grep -E "FAIL|failed|disagree|does not build" | head -60 | cut -c1-200 | awk '{printf "%s%%0A", $0}')
    first=$(printf '%s\n' "$clean" | grep -m1 -n -E "FAIL" | cut -d: -f1)
    detail=""
    [ -n "$first" ] && detail=$(printf '%s\n' "$clean" | sed -n "${first},$((first + 40))p" | cut -c1-200 | awk '{printf "%s%%0A", $0}')
    [ -n "$names" ] && echo "::error title=test.sh $(basename "$log") (which)::$names"
    [ -n "$detail" ] && echo "::error title=test.sh $(basename "$log") (first)::$detail"
  done
  return 0
}

echo "------------------------------------------------------------"
if [ "$failed" -ne 0 ]; then
  printf "${RED}something failed${NC}\n"
  annotate_failures
  exit 1
fi
printf "${GREEN}everything passed${NC}\n"
