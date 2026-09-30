#!/bin/sh
# replay.sh - a game is its commands: check that recording one and playing
# the recording back reproduces it exactly.
#
#   ./build.sh && ./replay.sh
#
# Every tests/*.play is played once with --record, then the recording is
# played back with no other input, and the two runs' --state -- every entity,
# target, order and cooldown, and the random generator, to the last few bits
# -- must be identical. So must the recording made while replaying: that is
# the check that nothing is lost between applying a command and writing it
# down.
#
# Then all of it again with every command held back four steps, as a
# networked game will hold them. Delayed, the games are not the ones the play
# tests describe, but each must still be exactly its own recording.
#
# A replay has no selection, since the selection belongs to whoever is
# watching; which is why the summary line, which counts it, is not compared.
# If the simulation ever came to read the selection, the states would part
# and this would fail. That is half of what it is for.
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
failed=0
total=0

# The play tests hold a command or two each. This is a minute of a real game
# against the opponent with a busy player, for every kind of command in
# quantity: a unit bought each second, whether or not there is the gold (a
# command that does nothing must replay as nothing), all selected and sent
# somewhere or at the enemy base in turn, a box drawn and the selection
# dropped now and then, and R every ten seconds, which starts a new game
# whenever one has ended.
{
  echo "# game"
  echo "# frames 3600"
  k=1
  while [ $k -lt 60 ]; do
    s=$((k * 60))
    echo "$s key $((49 + k % 3))"
    case $((k % 5)) in
      0) echo "$s key 97"; echo "$((s + 1)) click $((4 + k % 6)) $((2 + k % 7)) 0" ;;
      2) echo "$s key 97"; echo "$((s + 1)) rclick 12.5 4.5 0.6" ;;
      3) echo "$((s + 2)) drag 1 1 7 9"; echo "$((s + 3)) click $((3 + k % 8)) $((1 + k % 8)) 0" ;;
      4) echo "$((s + 2)) key 27" ;;
    esac
    [ $((k % 10)) -eq 0 ] && echo "$((s + 5)) key 114"
    k=$((k + 1))
  done
} > "$TMP/busy.play"

for delay in 0 4; do
  for play in "$HERE"/tests/*.play "$TMP/busy.play"; do
    name=$(basename "$play" .play)
    total=$((total + 1))
    frames=$(sed -n 's/^# frames \([0-9]*\)$/\1/p' "$play")
    mode=--skirmish
    grep -q '^# game$' "$play" && mode=""
    # shellcheck disable=SC2086
    "$HERE/rps" --frames "$frames" $mode --delay "$delay" --play "$play" \
      --record "$TMP/played" --state --shot "$TMP/played.bmp" > "$TMP/played.out" 2>&1
    "$HERE/rps" --frames "$frames" --replay "$TMP/played" \
      --record "$TMP/replayed" --state --shot "$TMP/replayed.bmp" > "$TMP/replayed.out" 2>&1
    grep -E '^(tick|gold) |^[0-9]+ team ' "$TMP/played.out" > "$TMP/played.state"
    grep -E '^(tick|gold) |^[0-9]+ team ' "$TMP/replayed.out" > "$TMP/replayed.state"
    problems=""
    [ -s "$TMP/played.state" ] || problems="no state printed"
    cmp -s "$TMP/played.state" "$TMP/replayed.state" ||
      problems="$problems${problems:+; }the replay's state differs"
    cmp -s "$TMP/played" "$TMP/replayed" ||
      problems="$problems${problems:+; }the replay recorded something else"
    commands=$(grep -c -v -E '^(seed|skirmish) ' "$TMP/played")
    label=$name
    [ "$delay" -eq 0 ] || label="$name, delay $delay"
    if [ -z "$problems" ]; then
      printf '  %-34s ok  %s commands\n' "$label" "$commands"
    else
      printf '  %-34s FAIL: %s\n' "$label" "$problems"
      diff "$TMP/played.state" "$TMP/replayed.state" | head -6 | sed 's/^/      | /'
      failed=$((failed + 1))
    fi
  done
done
if [ "$failed" -eq 0 ]; then
  echo "all $total replays matched"
else
  echo "$failed of $total replays differed"
  exit 1
fi
