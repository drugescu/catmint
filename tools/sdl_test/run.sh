#!/bin/sh
# Tests of lib/sdl.cmm that need SDL2 installed and no screen. Says so when
# SDL2 is missing rather than printing nothing.
#
#   tools/sdl_test/run.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

SDL_PREFIX=$(command -v brew >/dev/null 2>&1 && brew --prefix sdl2 2>/dev/null || true)
LIBS=""
[ -n "$SDL_PREFIX" ] && [ -d "$SDL_PREFIX/lib" ] && LIBS="-L $SDL_PREFIX/lib"
# shellcheck disable=SC2086
if ! "$ROOT/catmintc" -I "$ROOT/lib" $LIBS "$HERE/errors.cm" -o "$work/errors" \
      > "$work/build.log" 2>&1; then
  if grep -q "cannot find -lSDL2\|library not found\|unable to find library" "$work/build.log"; then
    echo "skipped: SDL2 is not installed"
    exit 0
  fi
  cat "$work/build.log"; exit 1
fi

# A video driver that is not there: SDL's error names it.
out=$(SDL_VIDEODRIVER=no_such_driver "$work/errors" 2>&1 || true)
case "$out" in
  *"could not initialise SDL:"*no_such_driver*) echo "SDL's error text reaches the program" ;;
  *) echo "the error did not carry SDL's reason:"; echo "$out"; exit 1 ;;
esac
