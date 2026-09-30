#!/bin/sh
# build.sh - compile the SDL2 shim and link it with the catmint program.
#
#   ./build.sh          -> ./rps
#   ./build.sh --run    -> ./rps, then run it
#
# catmintc has no notion of a plain .o file, only -l/-L (see catmintc and
# `link "..."` in rps.cm), so the shim is archived into a tiny static
# library first and pulled in the same way SDL2 itself is: `link "cmsdl"`
# in rps.cm becomes -lcmsdl, and the -L below is what lets the linker find
# it.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)

# Same discovery build-runtime.sh uses, and for the same reason: the shim,
# the runtime and the program all have to be built by one toolchain, or a
# function attribute one clang emits is one the other's back end refuses
# (CLAUDE.md's "Unsupported stack probing method" trap).
LLVM_BIN=${LLVM_BIN:-$(dirname "$(command -v llvm-link 2>/dev/null || \
                                  echo /opt/homebrew/opt/llvm@22/bin/llvm-link)")}
export LLVM_BIN
CLANG="$LLVM_BIN/clang"

SDL_PREFIX=$(command -v brew >/dev/null 2>&1 && brew --prefix sdl2 2>/dev/null || echo /opt/homebrew)
[ -d "$SDL_PREFIX/include/SDL2" ] || SDL_PREFIX=/opt/homebrew

"$CLANG" -O2 -c -I"$SDL_PREFIX/include" "$HERE/sdl_shim.c" -o "$HERE/sdl_shim.o"
ar rcs "$HERE/libcmsdl.a" "$HERE/sdl_shim.o"

"$ROOT/catmintc" -I "$HERE" -L "$HERE" -L "$SDL_PREFIX/lib" \
  -o "$HERE/rps" "$@" "$HERE/rps.cm"
echo "build.sh: wrote $HERE/rps"
