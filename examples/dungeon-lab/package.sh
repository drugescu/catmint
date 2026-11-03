#!/bin/sh
# Package the already-built native executable, without shipping the toolchain.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
DEST=${1:?Usage: package.sh OUTPUT_DIRECTORY}
mkdir -p "$DEST"
DEST=$(cd "$DEST" && pwd)
cp "$HERE/dungeon-lab" "$DEST/dungeon-lab"
cp "$HERE/README.md" "$DEST/README.md"
cp "$HERE/preview.png" "$DEST/preview.png"
cp "$ROOT/LICENSE" "$DEST/LICENSE"
"$DEST/dungeon-lab" --seed 42 --export "$DEST/example-42.svg"
git -C "$ROOT" archive --format=tar.gz --output="$DEST/source.tar.gz" HEAD
git -C "$ROOT" rev-parse HEAD > "$DEST/SOURCE_COMMIT"
echo "Dungeon Lab package: $DEST"
