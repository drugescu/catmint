#!/bin/sh
# build.sh - build pad.
#
#   ./build.sh          -> ./pad
#
# SDL and SDL_ttf come from the standard library (`using sdl`, `using ttf`), which catmintc finds
# by itself, as it finds Homebrew's library folder; so this is only the compiler run on pad.cm.
# No C is compiled.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
"$ROOT/catmintc" -o "$HERE/pad" "$@" "$HERE/pad.cm"
echo "build.sh: wrote $HERE/pad"
