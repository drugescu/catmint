#!/bin/sh
# build.sh - build the game.
#
#   ./build.sh          -> ./rps
#   ./build.sh --run    -> ./rps, then run it
#
# SDL comes from the standard library -- `using sdl`, which is catmint over
# bindings generated from SDL's own headers -- so this only says where SDL2
# is installed, since Homebrew's prefix is not on the linker's default path.
# No C is compiled.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)

# Homebrew keeps SDL2 off the linker's default path; a Linux package manager
# does not, and there nothing extra is needed.
LIBS=""
if command -v brew >/dev/null 2>&1; then
  SDL_PREFIX=$(brew --prefix sdl2 2>/dev/null || true)
  [ -n "$SDL_PREFIX" ] && [ -d "$SDL_PREFIX/lib" ] && LIBS="-L $SDL_PREFIX/lib"
fi

# shellcheck disable=SC2086
"$ROOT/catmintc" -I "$ROOT/lib" $LIBS -o "$HERE/rps" "$@" "$HERE/rps.cm"
echo "build.sh: wrote $HERE/rps"
