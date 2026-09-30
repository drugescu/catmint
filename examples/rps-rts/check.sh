#!/bin/sh
# check.sh - compare the catmint simulation with replica.py, frame by frame.
#
#   ./build.sh && ./check.sh
#
# For each frame count, runs `rps --frames N --dump` and replica.py N and
# requires the two to agree exactly: every surviving unit, in order, with
# position and health as fixed-point integers. Bases are not compared; nothing
# in this scenario reaches one.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
bad=0
for n in 1 2 5 10 30 60 100 150 200 235 260 290 320 400 500 800 1500 3000; do
  "$HERE/rps" --frames "$n" --dump --shot "$TMP/frame.bmp" 2>/dev/null \
    | grep -v '^after\|^closed' > "$TMP/catmint.txt"
  python3 "$HERE/replica.py" "$n" > "$TMP/replica.txt"
  if cmp -s "$TMP/catmint.txt" "$TMP/replica.txt"; then
    printf '  frame %-5s ok\n' "$n"
  else
    printf '  frame %-5s DIFFERS\n' "$n"
    diff "$TMP/catmint.txt" "$TMP/replica.txt" | head -6
    bad=1
  fi
done
[ "$bad" -eq 0 ] && echo "simulation matches the reference" || { echo "simulation DIFFERS from the reference"; exit 1; }
