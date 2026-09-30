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

SDL_PREFIX=$(command -v brew >/dev/null 2>&1 && brew --prefix sdl2 2>/dev/null || echo /opt/homebrew)
[ -d "$SDL_PREFIX/lib" ] || SDL_PREFIX=/opt/homebrew

"$ROOT/catmintc" -I "$ROOT/lib" -L "$SDL_PREFIX/lib" -o "$HERE/rps" "$@" "$HERE/rps.cm"
echo "build.sh: wrote $HERE/rps"
