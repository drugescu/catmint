#!/bin/sh
# play.sh - run every tests/*.play against pad and check what each says should
# happen.
#
#   ./build.sh && ./play.sh
#   SHOTS=/some/dir ./play.sh      also keep each test's final frame as a BMP
#   PLAY_ONLY='run_* good_build' ./play.sh   only the tests whose names match
#   PLAY_TIMEOUT=20 ./play.sh      seconds a test may take (90): a test that waits for a
#                                  build or a program that never ends fails, not hangs
#
# A play file drives pad with real SDL input events and, for typed text, the
# program's own text handler (see Pad.send in pad.cm). Its header says how many
# frames to run, what to start with, and what must, or must not, appear in the
# state pad prints afterwards:
#
#   # frames 10
#   # files notes.txt=hello   (files made in the working directory first)
#   # exec catmintc=#!/bin/sh\necho hi   (a file made executable)
#   # config-files settings=theme=Nord\n   (in the settings folder, first)
#   # config-file settings=theme=Nord\n    (and what it holds afterwards)
#   # open notes.txt          (start with this file)
#   # args --catmintc @ROOT@/catmintc   (more arguments; @ROOT@ is the repository)
#   # env TMPDIR=@DIR@/tmp     (variables pad runs with; @DIR@ is the test's own folder)
#   # gone pid.txt             (no process has the number that file holds, afterwards)
#   # expect cursor 1 6
#   # absent quit 1
#   # pixels 0 0 960 640 30 34 41 N
#   # file notes.txt=hello    (what a file holds, afterwards)
#
# "# pixels x0 y0 x1 y1 r g b n" counts pixels of one exact colour in the
# half-open rectangle of the frame the run saved: what pad drew, not what it
# says it drew. A line "# pixels ... n" with n written as "none" means there
# must be no such pixel, and "some" means at least one.
#
# The expectations are written by hand from the design, not recorded from a
# run, so a test can disagree with pad.
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
PAD="${PAD:-$HERE/pad}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIODRIVER=dummy
failed=0
total=0
for play in "$HERE"/tests/*.play; do
  name=$(basename "$play" .play)
  if [ -n "$PLAY_ONLY" ]; then
    wanted=0
    for pattern in $PLAY_ONLY; do
      # shellcheck disable=SC2254
      case "$name" in $pattern) wanted=1 ;; esac
    done
    [ "$wanted" -eq 1 ] || continue
  fi
  total=$((total + 1))
  frames=$(sed -n 's/^# frames \([0-9]*\)$/\1/p' "$play")
  shot="$TMP/$name.bmp"
  [ -n "$SHOTS" ] && shot="$SHOTS/$name.bmp"
  # Each test works in a directory of its own.
  dir="$TMP/work-$name"
  mkdir -p "$dir"
  # "# files a.txt=text": make files first. \n in the text is a newline.
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    fname=${spec%%=*}
    mkdir -p "$dir/$(dirname "$fname")"
    printf '%b' "${spec#*=}" > "$dir/$fname"
  done <<FILES
$(sed -n 's/^# files //p' "$play")
FILES
  # "# exec name=text": the same, made executable (a stand-in for a program).
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    fname=${spec%%=*}
    mkdir -p "$dir/$(dirname "$fname")"
    printf '%b' "${spec#*=}" > "$dir/$fname"
    chmod +x "$dir/$fname"
  done <<EXECS
$(sed -n 's/^# exec //p' "$play")
EXECS
  # Each test has a settings folder of its own, so none reads a real one:
  # "# config-files name=text" puts a file there first (themes/x.yaml, settings).
  PAD_CONFIG="$TMP/config-$name"
  export PAD_CONFIG
  mkdir -p "$PAD_CONFIG"
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    fname=${spec%%=*}
    mkdir -p "$PAD_CONFIG/$(dirname "$fname")"
    printf '%b' "${spec#*=}" > "$PAD_CONFIG/$fname"
  done <<CONFIGS
$(sed -n 's/^# config-files //p' "$play")
CONFIGS
  open=$(sed -n 's/^# open \(.*\)$/\1/p' "$play" | sed "s|@DIR@|$dir|g")
  # "# args ...": more arguments for pad; @ROOT@ is this repository.
  extra=$(sed -n 's/^# args \(.*\)$/\1/p' "$play" | sed "s|@ROOT@|$ROOT|g")
  # "# env NAME=value ...": variables pad runs with; @DIR@ is the test's own folder.
  envs=$(sed -n 's/^# env \(.*\)$/\1/p' "$play" | sed "s|@DIR@|$dir|g" | tr '\n' ' ')
  # shellcheck disable=SC2086
  (cd "$dir" && env $envs perl -e 'alarm shift; exec @ARGV' "${PLAY_TIMEOUT:-90}" "$PAD" $open $extra --play "$play" --frames "$frames" --shot "$shot") > "$TMP/out" 2>&1
  status=$?
  problems=""
  [ "$status" -eq 0 ] || problems="exit status $status"
  while IFS= read -r want; do
    [ -z "$want" ] && continue
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
  # "# file name=text": a file's contents after the run.
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    fname=${spec%%=*}
    printf '%b' "${spec#*=}" > "$TMP/want"
    cmp -s "$TMP/want" "$dir/$fname" || problems="$problems${problems:+; }file $fname is not what it should be"
  done <<FILECHECK
$(sed -n 's/^# file //p' "$play")
FILECHECK
  # "# gone name": the file holds a process number, and there is no such process now.
  while IFS= read -r fname; do
    [ -z "$fname" ] && continue
    pid=$(cat "$dir/$fname" 2>/dev/null)
    if [ -z "$pid" ]; then
      problems="$problems${problems:+; }$fname has no process number in it"
    elif kill -0 "$pid" 2>/dev/null; then
      problems="$problems${problems:+; }process $pid from $fname is still running"
      kill -9 "$pid" 2>/dev/null
    fi
  done <<GONE
$(sed -n 's/^# gone //p' "$play")
GONE
  # "# config-file name=text": a file in the settings folder, afterwards.
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    fname=${spec%%=*}
    printf '%b' "${spec#*=}" > "$TMP/want"
    cmp -s "$TMP/want" "$PAD_CONFIG/$fname" || problems="$problems${problems:+; }config file $fname is not what it should be"
  done <<CONFIGCHECK
$(sed -n 's/^# config-file //p' "$play")
CONFIGCHECK
  while IFS= read -r spec; do
    [ -z "$spec" ] && continue
    want=${spec##* }
    box=${spec% *}
    got=$(python3 "$HERE/../../tools/pixels.py" "$shot" $box)
    case "$want" in
      none) [ "$got" = 0 ] || problems="$problems${problems:+; }pixels $box: counted $got, wanted none" ;;
      some) [ "$got" -gt 0 ] || problems="$problems${problems:+; }pixels $box: counted none, wanted some" ;;
      *)    [ "$got" = "$want" ] || problems="$problems${problems:+; }pixels $spec: counted $got" ;;
    esac
  done <<PIXELS
$(sed -n 's/^# pixels //p' "$play")
PIXELS
  if [ -z "$problems" ]; then
    printf '  %-26s ok\n' "$name"
  else
    printf '  %-26s FAIL: %s\n' "$name" "$problems"
    sed 's/^/      | /' "$TMP/out"
    failed=$((failed + 1))
  fi
done
if [ "$failed" -eq 0 ]; then
  echo "all $total pad play tests passed"
else
  echo "$failed of $total pad play tests failed"
  exit 1
fi
