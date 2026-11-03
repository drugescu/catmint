#!/bin/sh
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
"$ROOT/catmintc" -o "$HERE/dungeon-lab" "$@" "$HERE/lab.cm"
