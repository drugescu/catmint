#!/bin/sh
# build.sh - build pad.
#
#   ./build.sh          -> ./pad
#
# SDL comes from the standard library -- `using sdl`, catmint over bindings
# generated from SDL's own headers -- so this only says where SDL2 is
# installed, since Homebrew's prefix is not on the linker's default path.
# No C is compiled.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)

LIBS=""
if command -v brew >/dev/null 2>&1; then
  for formula in sdl2 sdl2_ttf; do
    PREFIX=$(brew --prefix "$formula" 2>/dev/null || true)
    [ -n "$PREFIX" ] && [ -d "$PREFIX/lib" ] && LIBS="$LIBS -L $PREFIX/lib"
  done
fi

# shellcheck disable=SC2086
"$ROOT/catmintc" -I "$ROOT/lib" $LIBS -o "$HERE/pad" "$@" "$HERE/pad.cm"
echo "build.sh: wrote $HERE/pad"
