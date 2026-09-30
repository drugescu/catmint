#!/bin/sh
# play.sh - run every tests/*.play and check what each says should happen.
#
#   ./build.sh && ./play.sh
#   SHOTS=/some/dir ./play.sh      also keep each test's final frame as a BMP
#
# A play file drives the game with real SDL input events (see Script in
# rps.cm). Its header says how many steps to run and what must, or must not,
# appear in what the game prints afterwards:
#
#   # frames 10
#   # expect selected 4  over
#   # absent idle
#   # pixels 44 16 76 36 231 226 214 320
#
# The last counts pixels of one exact colour in a rectangle of the frame the
# run saved: what the HUD drew rather than what the game says it has.
#
# The expectations are written by hand from the rules, not recorded from a
# run, so a test can disagree with the game.
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
failed=0
total=0
for play in "$HERE"/tests/*.play; do
  name=$(basename "$play" .play)
  total=$((total + 1))
  frames=$(sed -n 's/^# frames \([0-9]*\)$/\1/p' "$play")
  shot="$TMP/$name.bmp"
  [ -n "$SHOTS" ] && shot="$SHOTS/$name.bmp"
  "$HERE/rps" --frames "$frames" --play "$play" --shot "$shot" > "$TMP/out" 2>&1
  status=$?
  problems=""
  [ "$status" -eq 0 ] || problems="exit status $status"
  while IFS= read -r want; do
    grep -qF -- "$want" "$TMP/out" || problems="$problems${problems:+; }missing '$want'"
  done <<EXPECT
$(sed -n 's/^# expect //p' "$play")
EXPECT
  while IFS= read -r unwanted; do
    [ -z "$unwanted" ] && continue
    grep -qF -- "$unwanted" "$TMP/out" && problems="$problems${problems:+; }unwanted '$unwanted'"
  done <<ABSENT
$(sed -n 's/^# absent //p' "$play")
ABSENT
  # "# pixels x0 y0 x1 y1 r g b n": exactly n pixels of that colour in the
  # half-open rectangle, counted in the frame the run saved.
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    got=$(python3 "$HERE/pixels.py" "$shot" $spec)
    want=${spec##* }
    [ "$got" = "$want" ] || problems="$problems${problems:+; }pixels $spec: counted $got"
  done <<PIXELS
$(sed -n 's/^# pixels //p' "$play")
PIXELS
  if [ -z "$problems" ]; then
    printf '  %-20s ok\n' "$name"
  else
    printf '  %-20s FAIL: %s\n' "$name" "$problems"
    sed 's/^/      | /' "$TMP/out"
    failed=$((failed + 1))
  fi
done
if [ "$failed" -eq 0 ]; then
  echo "all $total play tests passed"
else
  echo "$failed of $total play tests failed"
  exit 1
fi
