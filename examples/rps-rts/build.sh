#!/bin/sh
# build.sh - build the game.
#
#   ./build.sh          -> ./rps
#   ./build.sh --run    -> ./rps, then run it
#
# SDL comes from the standard library -- `using sdl`, which is catmint over bindings generated
# from SDL's own headers -- and catmintc finds both that and Homebrew's library folder itself,
# so this is only the compiler run on rps.cm. No C is compiled.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
"$ROOT/catmintc" -o "$HERE/rps" "$@" "$HERE/rps.cm"
echo "build.sh: wrote $HERE/rps"
