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

# Textures and text: a frame drawn with a known texture and known glyphs, then
# compared pixel by pixel with what the font data says it should be.
if ! "$ROOT/catmintc" -I "$ROOT/lib" $LIBS "$HERE/texture.cm" -o "$work/texture" \
      > "$work/texture.log" 2>&1; then
  cat "$work/texture.log"; exit 1
fi
if ! SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIODRIVER=dummy \
      "$work/texture" "$work/texture.bmp" > "$work/texture.out" 2>&1; then
  cat "$work/texture.out"; exit 1
fi
grep -q "width 72" "$work/texture.out" || { echo "Font.width is wrong:"; cat "$work/texture.out"; exit 1; }
python3 "$HERE/check_texture.py" "$work/texture.bmp" "$ROOT/lib/fontdata.cmm"
