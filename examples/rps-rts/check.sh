#!/bin/sh
# check.sh - compare the catmint game with replica.py, bit for bit.
#
#   ./build.sh && ./check.sh
#
# Three scenarios, each at several points in time:
#   skirmish   the fixed battle, no opponent: units, targets, damage
#   game       a real game with no player input: the opponent's AI, gold,
#              spawning, a base falling, the game ending
#   countered  a real game where the player buys units, so the AI has
#              something to counter
# Every surviving unit is compared, in order, with position and health as
# fixed-point integers, then both bases, the gold and who won.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
bad=0

compare() {
  label=$1; n=$2; rps_args=$3; replica_args=$4
  # shellcheck disable=SC2086
  "$HERE/rps" --frames "$n" --dump $rps_args --shot "$TMP/frame.bmp" 2>/dev/null \
    | grep -v '^after\|^closed\|^unit ' > "$TMP/catmint.txt"
  # shellcheck disable=SC2086
  python3 "$HERE/replica.py" "$n" $replica_args > "$TMP/replica.txt"
  if cmp -s "$TMP/catmint.txt" "$TMP/replica.txt"; then
    printf '  %-10s frame %-5s ok  %s\n' "$label" "$n" "$(tail -1 "$TMP/replica.txt")"
  else
    printf '  %-10s frame %-5s DIFFERS\n' "$label" "$n"
    diff "$TMP/catmint.txt" "$TMP/replica.txt" | head -6
    bad=1
  fi
}

for n in 1 30 150 235 290 500 1500 3000; do
  compare skirmish "$n" --skirmish ""
done

for n in 210 211 420 1000 2000 3000 4000; do
  compare game "$n" "" --game
done

# Three rocks at once and one more later, as keys 1 1 1 and 1 at step 400:
# the same presses reach the game as SDL events and the replica as spawns.
printf '1 key 49\n1 key 49\n1 key 49\n400 key 49\n' > "$TMP/countered.play"
for n in 211 420 700 1500 3000; do
  compare countered "$n" "--play $TMP/countered.play" "--game --spawn 1:0,1:0,1:0,400:0"
done

[ "$bad" -eq 0 ] && echo "simulation matches the reference" || { echo "simulation DIFFERS from the reference"; exit 1; }
